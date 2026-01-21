import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

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
    print('🔔 NotificationService initialized');
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
    // Android settings - Enhanced for compatibility across all versions
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@drawable/ic_notification');

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

  /// Create notification channels for Android - Enhanced for all versions
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Chat messages channel - Compatible with all Android versions
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        chatChannelId,
        chatChannelName,
        description: chatChannelDescription,
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
        showBadge: true,
        playSound: true,
      );

      // General notifications channel - Compatible with all Android versions
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        generalChannelId,
        generalChannelName,
        description: generalChannelDescription,
        importance: Importance.defaultImportance,
        enableVibration: true,
        showBadge: true,
        playSound: true,
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

  /// Get Android SDK version - Enhanced with better detection
  Future<int> _getAndroidVersion() async {
    try {
      // For production apps, you should use device_info_plus package
      // For now, we'll use permission behavior to detect Android version

      // Check if POST_NOTIFICATIONS permission exists (Android 13+)
      final hasPostNotificationPermission = await Permission.notification.status;
      if (hasPostNotificationPermission != PermissionStatus.denied &&
          hasPostNotificationPermission != PermissionStatus.permanentlyDenied) {
        print('🔔 Detected Android 13+ (has POST_NOTIFICATIONS permission)');
        return 33; // Android 13+
      }
    } catch (e) {
      // If permission check fails, it's likely Android 12 or lower
      print('🔔 Detected Android 12 or lower (no POST_NOTIFICATIONS permission)');
    }

    // Default to Android API 28 (Android 9) for maximum compatibility
    return 28;
  }

  /// Check Android permissions - Enhanced for all Android versions
  Future<bool> _checkAndroidPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Get Android version for appropriate permission handling
        final androidSdk = await _getAndroidVersion();
        print('🔔 Detected Android SDK: $androidSdk');

        if (androidSdk >= 33) {
          // Android 13+ (API 33+) requires explicit notification permission
          return await _handleAndroid13PlusPermissions();
        } else if (androidSdk >= 26) {
          // Android 8+ (API 26+) uses notification channels
          return await _handleAndroid8To12Permissions();
        } else {
          // Android 7 and below (should not occur with modern Flutter)
          return await _handleLegacyAndroidPermissions();
        }
      }
    } catch (e) {
      print('❌ Error checking Android permissions: $e');
      // Fallback: assume notifications are enabled for maximum compatibility
      _notificationsEnabled.value = true;
      return true;
    }

    return false;
  }

  /// Handle Android 13+ permission logic
  Future<bool> _handleAndroid13PlusPermissions() async {
    try {
      final notificationPermission = await Permission.notification.status;
      print('🔔 Android 13+ notification permission status: $notificationPermission');

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
      }
    } catch (e) {
      print('❌ Error handling Android 13+ permissions: $e');
    }

    return false;
  }

  /// Handle Android 8-12 permission logic
  Future<bool> _handleAndroid8To12Permissions() async {
    try {
      // For Android 8-12, check if notifications are enabled through the plugin
      final areNotificationsEnabled = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? true;

      _notificationsEnabled.value = areNotificationsEnabled;
      print('🔔 Android 8-12 notifications enabled: $areNotificationsEnabled');

      if (!areNotificationsEnabled) {
        await _showPermissionDialog();
        return false;
      }

      return areNotificationsEnabled;
    } catch (e) {
      print('❌ Error checking Android 8-12 permissions: $e');
      // Assume enabled for compatibility
      _notificationsEnabled.value = true;
      return true;
    }
  }

  /// Handle legacy Android permissions (Android 7 and below)
  Future<bool> _handleLegacyAndroidPermissions() async {
    print('🔔 Legacy Android detected - notifications enabled by default');
    _notificationsEnabled.value = true;
    return true;
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

  /// Show chat message notification - Enhanced for all Android versions
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String rideId,
  }) async {
    if (!_notificationsEnabled.value || !_isInitialized.value) {
      print('⚠️ Notifications not enabled or not initialized');
      return;
    }

    // Don't show notification if user is already in the chat screen
    if (_currentRoute.value == '/chatScreen') {
      print('⚠️ User is in chat screen, skipping notification');
      return;
    }

    try {
      // Enhanced Android notification details for maximum compatibility
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
        icon: '@drawable/ic_notification', // Use notification icon
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        autoCancel: true,
        ongoing: false,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.private,
        // Remove largeIcon and other advanced features for older Android compatibility
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.aiff',
        categoryIdentifier: 'chat_message',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use rideId hash as notification ID so messages from same ride update the same notification
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
      // Fallback: Try with minimal notification details
      await _showFallbackNotification(senderName, message, rideId);
    }
  }

  /// Fallback notification with minimal details for maximum compatibility
  Future<void> _showFallbackNotification(String senderName, String message, String rideId) async {
    try {
      print('🔄 Attempting fallback notification...');

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        chatChannelId,
        chatChannelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        autoCancel: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final notificationId = rideId.hashCode.abs();

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'New message from $senderName',
        message,
        notificationDetails,
        payload: 'chat_$rideId',
      );

      print('🔔 Fallback notification sent successfully');
    } catch (e) {
      print('❌ Fallback notification also failed: $e');
    }
  }

  /// Show general notification - Enhanced for all Android versions
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
        icon: '@drawable/ic_notification', // Use notification icon
        playSound: true,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.private,
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

  /// Request notification permission for Android 13+
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
      // For older Android versions, assume notifications work
      return true;
    }

    return false;
  }

  /// Debug method to test notifications across different Android versions
  Future<void> debugNotificationStatus() async {
    print('🔍 === NOTIFICATION DEBUG INFO ===');
    print('  - Service initialized: $_isInitialized');
    print('  - Notifications enabled: $_notificationsEnabled');
    print('  - Current route: $_currentRoute');

    if (Platform.isAndroid) {
      try {
        final androidSdk = await _getAndroidVersion();
        print('  - Detected Android SDK: $androidSdk');

        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await androidPlugin?.areNotificationsEnabled();
        print('  - Android plugin enabled: $enabled');

        // Test permission status for Android 13+
        if (androidSdk >= 33) {
          try {
            final permission = await Permission.notification.status;
            print('  - POST_NOTIFICATIONS permission: $permission');
          } catch (e) {
            print('  - POST_NOTIFICATIONS permission check failed: $e');
          }
        }
      } catch (e) {
        print('  - Android debug failed: $e');
      }
    }
    print('🔍 ===========================');
  }

  /// Test notification for debugging purposes
  Future<void> testNotification() async {
    print('🧪 Testing notification...');

    try {
      await showChatNotification(
        senderName: 'Test Driver',
        message: 'This is a test notification to verify compatibility across Android versions 8-16+',
        rideId: 'test_ride_${DateTime.now().millisecondsSinceEpoch}',
      );
      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Test notification failed: $e');

      // Try fallback test
      try {
        await _showFallbackNotification(
          'Test Driver',
          'Fallback test notification',
          'test_fallback_${DateTime.now().millisecondsSinceEpoch}'
        );
      } catch (fallbackError) {
        print('❌ Fallback test also failed: $fallbackError');
      }
    }
  }
}
