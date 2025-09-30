import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pick_u/routes/app_pages.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final RxBool _notificationsEnabled = false.obs;
  final RxBool _isInitialized = false.obs;

  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get isInitialized => _isInitialized.value;

  // Track current screen
  final RxString _currentRoute = ''.obs;
  String get currentRoute => _currentRoute.value;

  // Notification channels
  static const String chatChannelId = 'chat_messages';
  static const String chatChannelName = 'Chat Messages';
  static const String chatChannelDescription = 'Notifications for new chat messages';

  static const String generalChannelId = 'general_notifications';
  static const String generalChannelName = 'General Notifications';
  static const String generalChannelDescription = 'General app notifications';

  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeNotifications();
    _setupRouteListener();
    print('🔔 NotificationService initialized');
  }

  /// Setup route listener to track current screen
  void _setupRouteListener() {
    ever(AppPages.routeObserver as RxInterface, (_) {
      _currentRoute.value = Get.currentRoute;
      print('🧭 Current route: ${_currentRoute.value}');
    });
  }

  /// Update current route manually (call this from your RouteObserver)
  void updateCurrentRoute(String route) {
    _currentRoute.value = route;
    print('🧭 Route updated to: $route');
  }

  /// Initialize notification service
  Future<void> initializeNotifications() async {
    try {
      await _initializePlatformSpecifics();
      await checkAndRequestPermissions();
      _isInitialized.value = true;
      print('🔔 Notifications initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize notifications: $e');
    }
  }

  /// Initialize platform-specific notification settings
  Future<void> _initializePlatformSpecifics() async {
    // Android settings - FIXED: Use drawable notification icon
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('ic_notification');

    // iOS settings
    const DarwinInitializationSettings iosInitSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Chat messages channel
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        chatChannelId,
        chatChannelName,
        description: chatChannelDescription,
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
        showBadge: true,
      );

      // General notifications channel
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        generalChannelId,
        generalChannelName,
        description: generalChannelDescription,
        importance: Importance.defaultImportance,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(chatChannel);
      await androidPlugin.createNotificationChannel(generalChannel);

      print('📱 Android notification channels created');
    }
  }

  /// Check and request notification permissions with Android 12+ support
  Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      return await _checkAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _checkIOSPermissions();
    }
    return false;
  }

  /// Check Android permissions with Android 12+ support
  Future<bool> _checkAndroidPermissions() async {
    try {
      if (Platform.isAndroid) {
        final notificationPermission = await Permission.notification.status;
        print('🔔 Android notification permission status: $notificationPermission');

        if (notificationPermission.isDenied) {
          final result = await _requestNotificationPermission();
          _notificationsEnabled.value = result;
          return result;
        } else if (notificationPermission.isGranted) {
          _notificationsEnabled.value = true;
          return true;
        } else if (notificationPermission.isPermanentlyDenied) {
          await _showPermissionDialog();
          return false;
        } else {
          final areNotificationsEnabled = await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ?? false;

          _notificationsEnabled.value = areNotificationsEnabled;
          return areNotificationsEnabled;
        }
      }
    } catch (e) {
      print('❌ Error checking Android permissions: $e');
    }

    _notificationsEnabled.value = false;
    return false;
  }

  /// Request notification permission for Android 12+
  Future<bool> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();

      if (status.isGranted) {
        print('✅ Notification permission granted');
        return true;
      } else if (status.isDenied) {
        print('❌ Notification permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        print('❌ Notification permission permanently denied');
        await _showPermissionDialog();
        return false;
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
    }

    return false;
  }

  /// Check iOS permissions
  Future<bool> _checkIOSPermissions() async {
    try {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _notificationsEnabled.value = result ?? false;
      return result ?? false;
    } catch (e) {
      print('❌ Error checking iOS permissions: $e');
      _notificationsEnabled.value = false;
      return false;
    }
  }

  /// Show permission dialog for permanently denied permissions
  Future<void> _showPermissionDialog() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'To receive chat notifications, please enable notifications in your device settings.\n\n'
              'Go to Settings > Apps > Pick-U > Notifications and enable notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Handle notification tap - FIXED: Use correct route
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    print('🔔 Notification tapped with payload: $payload');

    if (payload != null) {
      _handleNotificationNavigation(payload);
    }
  }

  /// Handle navigation when notification is tapped - FIXED
  void _handleNotificationNavigation(String payload) {
    try {
      if (payload.startsWith('chat_')) {
        final rideId = payload.replaceFirst('chat_', '');

        // Navigate to chat screen with correct route
        Get.toNamed('/chatScreen', arguments: {'rideId': rideId});

        print('🔔 Navigating to chat screen for ride: $rideId');
      }
    } catch (e) {
      print('❌ Error handling notification navigation: $e');
    }
  }

  /// Show chat message notification - FIXED: Check if user is in chat + use rideId as notification ID
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String rideId,
  }) async {
    if (!_notificationsEnabled.value || !_isInitialized.value) {
      print('⚠️ Notifications not enabled or not initialized');
      return;
    }

    // FIXED: Don't show notification if user is already in the chat screen
    if (_currentRoute.value == '/chatScreen') {
      print('⚠️ User is in chat screen, skipping notification');
      return;
    }

    try {
      // FIXED: Use proper notification icon
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        chatChannelId,
        chatChannelName,
        channelDescription: chatChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
        showWhen: true,
        icon: 'ic_notification',  // FIXED: Use notification icon from drawable
        largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // FIXED: Use rideId hash as notification ID so messages from same ride update the same notification
      final notificationId = rideId.hashCode.abs();

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'New message from $senderName',
        message,
        notificationDetails,
        payload: 'chat_$rideId',
      );

      print('🔔 Chat notification sent: $senderName - $message (ID: $notificationId)');
    } catch (e) {
      print('❌ Failed to show chat notification: $e');
    }
  }

  /// Show general notification
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled.value || !_isInitialized.value) {
      print('⚠️ Notifications not enabled or not initialized');
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        generalChannelId,
        generalChannelName,
        channelDescription: generalChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
        icon: 'ic_notification',  // FIXED: Use notification icon
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('🔔 General notification sent: $title');
    } catch (e) {
      print('❌ Failed to show general notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🔔 All notifications cancelled');
  }

  /// Cancel notification for specific ride
  Future<void> cancelRideNotification(String rideId) async {
    final notificationId = rideId.hashCode.abs();
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    print('🔔 Cancelled notification for ride: $rideId');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return _notificationsEnabled.value;
  }

  /// Refresh permission status
  Future<void> refreshPermissionStatus() async {
    await checkAndRequestPermissions();
  }
}
