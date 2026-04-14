import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pick_u/services/share_pref.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const MethodChannel _debugChannel = MethodChannel('picku.notification_debug');

  final RxBool _notificationsEnabled = false.obs;
  final RxBool _isInitialized = false.obs;

  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get isInitialized => _isInitialized.value;

  // Track current screen
  final RxString _currentRoute = ''.obs;
  String get currentRoute => _currentRoute.value;

  // Notification channels
  static const String chatChannelId = 'chat_messages_pick_u_v4';
  static const String chatChannelName = 'Chat Messages';
  static const String chatChannelDescription = 'Notifications for new chat messages';

  static const String generalChannelId = 'general_notifications_pick_u_v4';
  static const String generalChannelName = 'General Notifications';
  static const String generalChannelDescription = 'General app notifications';

  /// FCM chat in foreground: same as chat UX but **system default** notification sound (not app raw).
  static const String chatPushChannelId = 'chat_messages_push_default_pick_u_v2';
  static const String chatPushChannelName = 'Chat Messages (Push)';
  static const String chatPushChannelDescription = 'Push chat alerts using the device default sound';

  /// Bump this when changing Android channel properties (sound/importance/etc).
  /// On Android 8+ channels are sticky; a version bump triggers delete+recreate.
  static const int kChannelsSchemaVersion = 2;

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

  /// Initialize notification service (channels + plugin only; permission is requested on MainMap, not at startup).
  Future<void> initializeNotifications() async {
    try {
      await _initializePlatformSpecifics();
      // Do NOT call checkAndRequestPermissions() here - requested only when user reaches MainMap
      _isInitialized.value = true;
      print('🔔 Notifications initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize notifications: $e');
    }
  }

  /// Initialize platform-specific notification settings
  /// All status bar notification icons use Pick U logo: res/drawable/ic_notification.png (from assets/images/ic_notification.png)
  Future<void> _initializePlatformSpecifics() async {
    // Android settings - Use Pick U logo for all notifications (ic_notification)
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
      final didMigrate =
          await SharedPrefsService.getDidMigrateNotificationChannelsV4();
      if (!didMigrate) {
        // One-time cleanup of legacy channels so new IDs take effect (Android 8+ channels are sticky).
        await androidPlugin.deleteNotificationChannel('chat_messages');
        await androidPlugin.deleteNotificationChannel('general_notifications');
        await androidPlugin.deleteNotificationChannel('chat_messages_v1');
        await androidPlugin.deleteNotificationChannel('general_notifications_v1');
        await androidPlugin.deleteNotificationChannel('chat_messages_pick_u_v2');
        await androidPlugin.deleteNotificationChannel('general_notifications_pick_u_v2');
        await androidPlugin.deleteNotificationChannel('chat_messages_pick_u_v3');
        await androidPlugin.deleteNotificationChannel('general_notifications_pick_u_v3');
        // Legacy FCM default channel used by older AndroidManifest configs.
        await androidPlugin.deleteNotificationChannel('general_notifications_pick_u_v3');

        // Also delete legacy push-channel id so sound changes take effect.
        await androidPlugin.deleteNotificationChannel('chat_messages_push_default_pick_u_v1');
      }

      // Versioned channel migration: delete+recreate current IDs when schema bumps.
      final storedSchema = await SharedPrefsService.getNotificationChannelsSchemaVersion();
      final needsSchemaMigration = storedSchema < kChannelsSchemaVersion;
      if (needsSchemaMigration) {
        try {
          // Delete and recreate current IDs so they pick up latest sound/importance again.
          await androidPlugin.deleteNotificationChannel(chatChannelId);
          await androidPlugin.deleteNotificationChannel(generalChannelId);
          await androidPlugin.deleteNotificationChannel(chatPushChannelId);
        } catch (_) {
          // Best-effort; channel may not exist yet.
        }
      }

      // Chat messages channel - Compatible with all Android versions
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        chatChannelId,
        chatChannelName,
        description: chatChannelDescription,
        importance: Importance.max, // Increased to Max for Heads-up + Sound
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
        showBadge: true,
        playSound: true,
      );

      // General / FCM: device default sound (no custom raw asset).
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        generalChannelId,
        generalChannelName,
        description: generalChannelDescription,
        importance: Importance.max,
        enableVibration: true,
        showBadge: true,
        playSound: true,
      );

      const AndroidNotificationChannel chatPushChannel = AndroidNotificationChannel(
        chatPushChannelId,
        chatPushChannelName,
        description: chatPushChannelDescription,
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
        showBadge: true,
        playSound: true,
      );

      await androidPlugin.createNotificationChannel(chatChannel);
      await androidPlugin.createNotificationChannel(generalChannel);
      await androidPlugin.createNotificationChannel(chatPushChannel);

      if (!didMigrate) {
        await SharedPrefsService.setDidMigrateNotificationChannelsV4(true);
      }
      if (needsSchemaMigration) {
        await SharedPrefsService.setNotificationChannelsSchemaVersion(kChannelsSchemaVersion);
      }

      print('📱 Android notification channels created');
    }
  }

  Future<void> _debugLogAndroidChannel(String channelId) async {
    if (!Platform.isAndroid) return;
    try {
      final info = await _debugChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getAndroidNotificationChannelInfo',
        {'channelId': channelId},
      );
      if (info == null) {
        print('🔇 ChannelDebug($channelId): no info (null)');
        return;
      }
      print('🔇 ChannelDebug($channelId): ${info.map((k, v) => MapEntry(k.toString(), v))}');
    } catch (e) {
      print('🔇 ChannelDebug($channelId) failed: $e');
    }
  }

  Future<void> debugNotificationSoundState() async {
    if (!Platform.isAndroid) {
      print('🔇 debugNotificationSoundState: Android only');
      return;
    }
    try {
      final enabled = await areNotificationsEnabled();
      print('🔇 Android notifications enabled: $enabled');
    } catch (e) {
      print('🔇 areNotificationsEnabled failed: $e');
    }

    await _debugLogAndroidChannel(generalChannelId);
    await _debugLogAndroidChannel(chatPushChannelId);
    await _debugLogAndroidChannel(chatChannelId);
  }

  /// After Firebase (or system) prompts for POST_NOTIFICATIONS, keep this flag in sync
  /// so foreground [showGeneralNotification] / [showChatNotification] are not skipped.
  Future<void> syncEnabledFromOs() async {
    if (!Platform.isAndroid) return;
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final sdk = await _getAndroidVersion();
      if (sdk >= 33) {
        final status = await Permission.notification.status;
        _notificationsEnabled.value = status.isGranted;
      } else {
        _notificationsEnabled.value = await androidPlugin?.areNotificationsEnabled() ?? true;
      }
    } catch (e) {
      print('❌ syncEnabledFromOs: $e');
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
      // Avoid extra dependencies: parse SDK from Android OS version string.
      // Typical format contains "SDK 33" etc.
      final os = Platform.operatingSystemVersion;
      final match = RegExp(r'SDK\s+(\d+)').firstMatch(os);
      final sdk = match == null ? null : int.tryParse(match.group(1) ?? '');
      if (sdk != null) {
        print('🔔 Android SDK (operatingSystemVersion): $sdk');
        return sdk;
      }
    } catch (e) {
      print('🔔 Failed to detect Android SDK: $e');
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
      } else if (payload.startsWith('ride_')) {
        final rideId = payload.replaceFirst('ride_', '');
        // Best-effort navigation to main map; downstream logic can load ride context if needed.
        Get.offAllNamed('/mainMap', arguments: {'rideId': rideId});
        print('🔔 Navigating to main map for ride: $rideId');
      }
    } catch (e) {
      print('❌ Error handling notification navigation: $e');
    }
  }

  /// Show chat message notification - Enhanced for all Android versions
  ///
  /// [useDeviceDefaultSound] — use for **FCM** chat pushes; in-app/SignalR chat keeps app sound when false.
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String rideId,
    bool useDeviceDefaultSound = false,
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
      // Log channel state before showing (helps diagnose "muted by Android")
      await _debugLogAndroidChannel(useDeviceDefaultSound ? chatPushChannelId : chatChannelId);
      final NotificationDetails notificationDetails = useDeviceDefaultSound
          ? NotificationDetails(
              android: AndroidNotificationDetails(
                chatPushChannelId,
                chatPushChannelName,
                channelDescription: chatPushChannelDescription,
                importance: Importance.high,
                priority: Priority.high,
                enableVibration: true,
                enableLights: true,
                ledColor: Colors.blue,
                ledOnMs: 1000,
                ledOffMs: 500,
                showWhen: true,
                icon: '@drawable/ic_notification',
                playSound: true,
                autoCancel: true,
                ongoing: false,
                category: AndroidNotificationCategory.message,
                visibility: NotificationVisibility.private,
                groupKey: 'ride_chat_$rideId',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                sound: 'default',
                interruptionLevel: InterruptionLevel.timeSensitive,
                categoryIdentifier: 'chat_message',
              ),
            )
          : NotificationDetails(
              android: AndroidNotificationDetails(
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
                icon: '@drawable/ic_notification',
                playSound: true,
                autoCancel: true,
                ongoing: false,
                category: AndroidNotificationCategory.message,
                visibility: NotificationVisibility.private,
                groupKey: 'ride_chat_$rideId',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                sound: 'default',
                interruptionLevel: InterruptionLevel.timeSensitive,
                categoryIdentifier: 'chat_message',
              ),
            );

      // Use a unique id per message so Android alerts (sound) every time.
      // Grouping is handled via groupKey in the Android notification details.
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

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
      await _showFallbackNotification(senderName, message, rideId, useDeviceDefaultSound: useDeviceDefaultSound);
    }
  }

  /// Fallback notification with minimal details for maximum compatibility
  Future<void> _showFallbackNotification(
    String senderName,
    String message,
    String rideId, {
    bool useDeviceDefaultSound = false,
  }) async {
    try {
      print('🔄 Attempting fallback notification...');

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        useDeviceDefaultSound ? chatPushChannelId : chatChannelId,
        useDeviceDefaultSound ? chatPushChannelName : chatChannelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification', // Pick U logo
        autoCancel: true,
        playSound: true,
        groupKey: 'ride_chat_$rideId',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

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

  /// Show general notification (push / FCM foreground) — **device default** sound, not app raw.
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
      // Log channel state before showing (helps diagnose "muted by Android")
      await _debugLogAndroidChannel(generalChannelId);
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        generalChannelId,
        generalChannelName,
        channelDescription: generalChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        icon: '@drawable/ic_notification', // Pick U logo - status bar icon
        playSound: true,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.private,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
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

  /// Cancel notification by id (e.g. foreground service notification).
  Future<void> cancelNotificationById(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    print('🔔 Cancelled notification id: $notificationId');
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
