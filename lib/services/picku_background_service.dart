import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String pickuServiceChannelId = 'picku_ride_service';
const String pickuServiceChannelName = 'Pick U Ride Service';
const String pickuServiceChannelDesc =
    'Keeps your ride connection active in the background';
const int pickuServiceNotificationId = 9999;

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  if (Platform.isAndroid) {
    final flnPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      pickuServiceChannelId,
      pickuServiceChannelName,
      description: pickuServiceChannelDesc,
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );

    await flnPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: pickuServiceChannelId,
      initialNotificationTitle: 'Pick U',
      initialNotificationContent: 'Connecting to your ride...',
      foregroundServiceNotificationId: pickuServiceNotificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onServiceStart,
      onBackground: _onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final flnPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  service.on('stop').listen((event) async {
    // Cancel the notification when service stops so it disappears (show only when running).
    if (Platform.isAndroid) {
      await flnPlugin.cancel(pickuServiceNotificationId);
    }
    service.stopSelf();
  });

  service.on('updateNotification').listen((event) {
    if (event != null && Platform.isAndroid) {
      final title = event['title'] as String? ?? 'Pick U';
      final body = event['body'] as String? ?? 'Ride service is running';

      flnPlugin.show(
        pickuServiceNotificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            pickuServiceChannelId,
            pickuServiceChannelName,
            icon: '@drawable/ic_notification', // Pick U logo - same as res/drawable/ic_notification.png
            ongoing: true,
            autoCancel: false,
            playSound: false,
            enableVibration: false,
            importance: Importance.low,
            priority: Priority.low,
            category: AndroidNotificationCategory.service,
          ),
        ),
      );
    }
  });

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) {
        timer.cancel();
        return;
      }
    }
    service.invoke('heartbeat', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
