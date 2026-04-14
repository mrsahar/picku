import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/routes/app_routes.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/services/global_variables.dart';
import 'package:pick_u/services/notification_service.dart';
import 'package:pick_u/services/share_pref.dart';

// Keep these IDs in sync with `NotificationService` (do not rely on it in the background isolate).
const String _bgChatPushChannelId = 'chat_messages_push_default_pick_u_v2';
const String _bgChatPushChannelName = 'Chat Messages (Push)';
const String _bgGeneralChannelId = 'general_notifications_pick_u_v4';
const String _bgGeneralChannelName = 'General Notifications';

@pragma('vm:entry-point')
Future<void> _bgEnsureAndroidChannels(FlutterLocalNotificationsPlugin fln) async {
  if (!Platform.isAndroid) return;
  final androidPlugin =
      fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin == null) return;

  // Create-if-missing is safe; we intentionally do not delete channels in background.
  const chatPushChannel = AndroidNotificationChannel(
    _bgChatPushChannelId,
    _bgChatPushChannelName,
    description: 'Push chat alerts using the device default sound',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  const generalChannel = AndroidNotificationChannel(
    _bgGeneralChannelId,
    _bgGeneralChannelName,
    description: 'General app notifications',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  await androidPlugin.createNotificationChannel(chatPushChannel);
  await androidPlugin.createNotificationChannel(generalChannel);
}

@pragma('vm:entry-point')
Future<void> _bgShowLocalNotification({
  required RemoteMessage message,
  required Map<String, dynamic> data,
}) async {
  final fln = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@drawable/ic_notification'),
    iOS: DarwinInitializationSettings(),
  );
  await fln.initialize(initSettings);
  await _bgEnsureAndroidChannels(fln);

  final type = (data['type'] ?? '').toString();
  final rideId = (data['rideId'] ?? '').toString();
  final title =
      message.notification?.title ?? (data['title'] ?? (type == 'ride_chat_message' ? 'New message' : 'PickU')).toString();
  final body = message.notification?.body ?? (data['body'] ?? data['message'] ?? '').toString();

  if (type.toLowerCase() == 'ride_chat_message' && rideId.isNotEmpty) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _bgChatPushChannelId,
        _bgChatPushChannelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: '@drawable/ic_notification',
        category: AndroidNotificationCategory.message,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'chat_message',
      ),
    );

    await fln.show(
      rideId.hashCode.abs(),
      title,
      body,
      details,
      payload: 'chat_$rideId',
    );
    return;
  }

  // Generic fallback for data-only messages (including ride updates).
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _bgGeneralChannelId,
      _bgGeneralChannelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@drawable/ic_notification',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    ),
  );

  await fln.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
    payload: rideId.isNotEmpty ? 'ride_$rideId' : null,
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep background handler minimal. No UI work here.
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  // Only show a local notification for data-only messages; otherwise the OS will display it.
  try {
    if (message.notification != null) return;
    final data = message.data;
    if (data.isEmpty) return;
    await _bgShowLocalNotification(message: message, data: Map<String, dynamic>.from(data));
  } catch (_) {}
}

class PushService extends GetxService {
  static PushService get to => Get.find<PushService>();

  final RxString _fcmToken = ''.obs;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  String get currentToken => _fcmToken.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadCachedToken();
    await ensurePermissions();
    await _syncTokenFromFcm();
    _listenTokenRefresh();
    _listenMessages();
    await _handleColdStartMessage();
  }

  Future<void> ensurePermissions() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      if (Platform.isAndroid && Get.isRegistered<NotificationService>()) {
        await NotificationService.to.syncEnabledFromOs();
      }
    } catch (_) {}
  }

  Future<void> _loadCachedToken() async {
    final cached = await SharedPrefsService.getFcmToken();
    if (cached != null && cached.isNotEmpty) {
      _fcmToken.value = cached;
    }
  }

  Future<void> _syncTokenFromFcm() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _setToken(token, sendToServerIfLoggedIn: false);
    } catch (_) {}
  }

  void _listenTokenRefresh() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _setToken(token, sendToServerIfLoggedIn: true);
    });
  }

  void _listenMessages() {
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      await _handleIncomingMessage(message, appWasOpenedByTap: false);
    });

    _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleIncomingMessage(message, appWasOpenedByTap: true);
    });
  }

  Future<void> _handleColdStartMessage() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        await _handleIncomingMessage(initial, appWasOpenedByTap: true);
      }
    } catch (_) {}
  }

  Future<void> _setToken(String token, {required bool sendToServerIfLoggedIn}) async {
    _fcmToken.value = token;
    await SharedPrefsService.saveFcmToken(token);

    if (!sendToServerIfLoggedIn) return;

    final jwt = GlobalVariables.instance.userToken;
    if (jwt.isEmpty) return;

    try {
      final api = Get.find<ApiProvider>();
      await api.updateFcmToken(token);
    } catch (_) {}
  }

  Future<void> _handleIncomingMessage(RemoteMessage message, {required bool appWasOpenedByTap}) async {
    final data = message.data;
    if (data.isEmpty) return;

    final type = (data['type'] ?? '').toString();
    final rideId = (data['rideId'] ?? '').toString();

    final typeLower = type.toLowerCase();
    if (typeLower == 'ride_completed') {
      await _tryAutoCompleteRideFromFcm(Map<String, dynamic>.from(data));
    }

    if (!appWasOpenedByTap) {
      await _showForegroundNotification(type: type, rideId: rideId, data: data, message: message);
      return;
    }

    _routeFromData(type: type, rideId: rideId, data: data);
  }

  /// When SignalR missed trip end, capture held fare from FCM then show tip-only UI (see [RideBookingController.handleRideCompletedFromPush]).
  Future<void> _tryAutoCompleteRideFromFcm(Map<String, dynamic> data) async {
    if (!Get.isRegistered<RideBookingController>()) return;
    try {
      await Get.find<RideBookingController>().handleRideCompletedFromPush(data);
    } catch (e) {
      print('PushService: FCM ride_completed handling error: $e');
    }
  }

  Future<void> _showForegroundNotification({
    required String type,
    required String rideId,
    required Map<String, dynamic> data,
    required RemoteMessage message,
  }) async {
    if (!Get.isRegistered<NotificationService>()) return;

    final title = message.notification?.title ?? _titleFromType(type);
    final body = message.notification?.body ?? (data['body'] ?? data['message'] ?? '').toString();

    switch (type) {
      case 'ride_chat_message':
        final senderName = (data['senderName'] ?? data['senderRole'] ?? 'New message').toString();
        if (rideId.isNotEmpty) {
          await NotificationService.to.showChatNotification(
            senderName: senderName,
            message: body,
            rideId: rideId,
            useDeviceDefaultSound: true,
          );
        } else {
          await NotificationService.to.showGeneralNotification(title: title, body: body);
        }
        break;
      default:
        await NotificationService.to.showGeneralNotification(
          title: title,
          body: body,
          payload: rideId.isNotEmpty ? 'ride_$rideId' : null,
        );
        break;
    }
  }

  void _routeFromData({required String type, required String rideId, required Map<String, dynamic> data}) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'ride_chat_message':
        if (rideId.isNotEmpty) {
          Get.toNamed(AppRoutes.chatScreen, arguments: {'rideId': rideId});
        }
        break;
      case 'ride_completed':
        Get.offAllNamed(AppRoutes.mainMap);
        Future.delayed(const Duration(milliseconds: 800), () async {
          await _tryAutoCompleteRideFromFcm(Map<String, dynamic>.from(data));
        });
        break;
      case 'payment_success':
        Get.offAllNamed(AppRoutes.mainMap);
        break;
      default:
        if (rideId.isNotEmpty) {
          Get.offAllNamed(AppRoutes.mainMap);
        }
        break;
    }
  }

  String _titleFromType(String type) {
    switch (type) {
      case 'ride_completed':
        return 'Ride completed';
      case 'payment_success':
        return 'Payment successful';
      case 'ride_chat_message':
        return 'New message';
      default:
        return 'PickU';
    }
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    super.onClose();
  }
}

