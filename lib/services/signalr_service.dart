import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/services/map_service.dart';
import 'package:pick_u/services/global_variables.dart';
import 'package:pick_u/services/notification_service.dart';
import 'package:pick_u/services/picku_background_service.dart';
import 'package:signalr_core/signalr_core.dart';

enum SignalRConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

class SignalRService extends GetxService with WidgetsBindingObserver {
  static SignalRService get to => Get.find<SignalRService>();

  static const String hubUrl = 'https://api.pickurides.com/ridechathub';
  static const Duration retryInterval = Duration(seconds: 5);

  HubConnection? _connection;
  bool _isConnected = false;
  String? _currentRideId;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 10;

  bool _isAppInForeground = true;
  bool get isAppInForeground => _isAppInForeground;

  HubConnection? get connection => _connection;

  final connectionStatus = SignalRConnectionStatus.disconnected.obs;

  final driverLatitude = 0.0.obs;
  final driverLongitude = 0.0.obs;
  final driverLastUpdate = DateTime.now().obs;
  final isDriverLocationActive = false.obs;

  MapService get _mapService => Get.find<MapService>();
  GlobalVariables get _globalVars => GlobalVariables.instance;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    print(' SAHAr SignalR: Service initialized, starting connection...');
    initializeConnection();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    print(' SAHAr SignalR: Service closing, cleaning up connection...');
    _retryTimer?.cancel();
    dispose();
    super.onClose();
  }

  // ─── App Lifecycle ────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print(' SAHAr SignalR: App resumed to foreground');
        _isAppInForeground = true;
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        print(' SAHAr SignalR: App moved to background');
        _isAppInForeground = false;
        break;
      case AppLifecycleState.inactive:
        _isAppInForeground = false;
        break;
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        break;
      default:
        break;
    }
  }

  void _onAppResumed() {
    if (!_isConnected && _currentRideId != null) {
      print(' SAHAr SignalR: Reconnecting after app resume...');
      _retryAttempts = 0;
      initializeConnection();
    }
  }

  // ─── Foreground Service ───────────────────────────────────────────

  Future<void> _startForegroundService(String body) async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        await Future.delayed(const Duration(milliseconds: 800));
      }
      _updateForegroundNotification(body);
      print(' SAHAr SignalR: Foreground service started');
    } catch (e) {
      print(' SAHAr SignalR: Error starting foreground service: $e');
    }
  }

  Future<void> _stopForegroundService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stop');
        // Dismiss notification immediately when service is not running (show only when running).
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.cancelNotificationById(pickuServiceNotificationId);
        } catch (_) {}
        print(' SAHAr SignalR: Foreground service stopped');
      }
    } catch (e) {
      print(' SAHAr SignalR: Error stopping foreground service: $e');
    }
  }

  void _updateForegroundNotification(String body) {
    try {
      final service = FlutterBackgroundService();
      service.invoke('updateNotification', {
        'title': 'Pick U',
        'body': body,
      });
    } catch (e) {
      print(' SAHAr SignalR: Error updating foreground notification: $e');
    }
  }

  // ─── SignalR Connection ───────────────────────────────────────────

  Future<void> initializeConnection() async {
    try {
      connectionStatus.value = SignalRConnectionStatus.connecting;

      final token = _globalVars.userToken;

      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect([1000, 2000, 5000, 10000, 30000])
          .build();

      _connection!.on('RideStatusChanged', (message) {
        print(' SAHAr SignalR: Ride Status Changed: $message');
        if (message != null && message.isNotEmpty) {
          _handleRideStatusUpdate(message[0]);
        }
      });

      _connection!.on('ReceiveRideLocation', (message) {
        print(' SAHAr SignalR: Received Location: $message');
        if (message != null && message.isNotEmpty) {
          _handleLocationUpdate(message[0]);
        }
      });

      _connection!.onclose((error) {
        print(' SAHAr SignalR: Connection closed: $error');
        _isConnected = false;
        isDriverLocationActive.value = false;
        connectionStatus.value = SignalRConnectionStatus.disconnected;

        if (_currentRideId != null) {
          _updateForegroundNotification('Reconnecting to ride service...');
        }
        _startRetryTimer();
      });

      _connection!.onreconnecting((error) {
        print(' SAHAr SignalR: Reconnecting: $error');
        connectionStatus.value = SignalRConnectionStatus.reconnecting;
        if (_currentRideId != null) {
          _updateForegroundNotification('Reconnecting to ride service...');
        }
      });

      _connection!.onreconnected((connectionId) {
        print(' SAHAr SignalR: Reconnected with ID: $connectionId');
        _isConnected = true;
        connectionStatus.value = SignalRConnectionStatus.connected;
        _retryAttempts = 0;
        _retryTimer?.cancel();

        if (_currentRideId != null) {
          subscribeToRide(_currentRideId!);
          _updateForegroundNotification('Connected — Tracking your ride');
        }
      });

      await _connection!.start();
      _isConnected = true;
      connectionStatus.value = SignalRConnectionStatus.connected;
      _retryAttempts = 0;
      print(' SAHAr SignalR: Successfully connected to RideHub');

    } catch (e) {
      print(' SAHAr SignalR: Failed to connect: $e');
      _isConnected = false;
      connectionStatus.value = SignalRConnectionStatus.error;
      _startRetryTimer();
    }
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();

    if (_retryAttempts < maxRetryAttempts) {
      _retryAttempts++;
      print(
          ' SAHAr SignalR: Starting retry timer (attempt $_retryAttempts/$maxRetryAttempts)');

      _retryTimer = Timer(retryInterval, () {
        if (!_isConnected) {
          print(' SAHAr SignalR: Retrying connection...');
          initializeConnection();
        }
      });
    } else {
      print(' SAHAr SignalR: Max retry attempts reached, backing off');
      connectionStatus.value = SignalRConnectionStatus.error;

      _retryTimer = Timer(const Duration(minutes: 1), () {
        _retryAttempts = 0;
        _startRetryTimer();
      });
    }
  }

  // ─── Ride Subscription ───────────────────────────────────────────

  Future<void> subscribeToRide(String rideId) async {
    if (!_isConnected || _connection == null) {
      print(' SAHAr SignalR: Cannot subscribe - not connected');
      return;
    }

    try {
      await _connection!.invoke('SubscribeToRide', args: [rideId]);
      _currentRideId = rideId;
      isDriverLocationActive.value = true;
      print(' SAHAr SignalR: Subscribed to ride $rideId');

      await _startForegroundService('Your driver is on the way');
    } catch (e) {
      print(' SAHAr SignalR: Failed to subscribe to ride: $e');
    }
  }

  Future<void> unsubscribeFromRide() async {
    if (!_isConnected || _connection == null || _currentRideId == null) {
      _currentRideId = null;
      await _stopForegroundService();
      return;
    }

    try {
      await _connection!
          .invoke('UnsubscribeFromRide', args: [_currentRideId!]);
      _currentRideId = null;
      isDriverLocationActive.value = false;
      print(' SAHAr SignalR: Unsubscribed from ride');

      await _stopForegroundService();
    } catch (e) {
      print(' SAHAr SignalR: Failed to unsubscribe: $e');
    }
  }

  Future<void> retryConnection() async {
    _retryTimer?.cancel();
    _retryAttempts = 0;
    await initializeConnection();
  }

  // ─── Event Handlers ──────────────────────────────────────────────

  void _handleRideStatusUpdate(dynamic rideData) {
    try {
      print(' SAHAr Processing ride status update: $rideData');
      final controller = Get.find<RideBookingController>();

      if (rideData is Map<String, dynamic>) {
        String statusString =
            (rideData['status'] ?? rideData['rideStatus'] ?? '').toString();

        RideStatus status;
        String serviceBody = '';

        switch (statusString.toLowerCase()) {
          case 'pending':
            status = RideStatus.pending;
            serviceBody = 'Finding you a driver nearby...';
            break;

          case 'arrived':
            status = RideStatus.driverArrived;
            controller.rideStatus.value = status;
            serviceBody = 'Your driver is waiting for you';
            if (_isAppInForeground) {
              controller.showDriverArrivedDialogFromSignalR();
            }
            break;

          case 'in-progress':
          case 'inprogress':
          case 'started':
            status = RideStatus.tripStarted;
            controller.rideStatus.value = status;
            serviceBody = 'Enjoy your ride! Trip in progress';
            if (_isAppInForeground) {
              Get.snackbar(
                'Trip Started',
                'Your driver has started the trip!',
                backgroundColor: Colors.green.withValues(alpha: 0.8),
                colorText: Colors.white,
              );
            }
            break;

          case 'completed':
            status = RideStatus.tripCompleted;
            controller.rideStatus.value = status;
            controller.endTrip();
            unsubscribeFromRide();
            break;

          case 'cancelled':
            status = RideStatus.cancelled;
            controller.rideStatus.value = status;
            unsubscribeFromRide();
            // Payment → review popup → reset (clearBooking when user dismisses review)
            controller.handleRideCancelledFromSignalR();
            break;

          default:
            print(' SAHAr Unknown status: $statusString');
            return;
        }

        // Only use foreground service notification (non-dismissible per Google ToS).
        // Do not show a separate dismissible notification for ride status.
        if (serviceBody.isNotEmpty) {
          _updateForegroundNotification(serviceBody);
        }

        print(' SAHAr Status updated to: $status');
      }
    } catch (e) {
      print(' SAHAr Error handling ride status update: $e');
    }
  }

  void _handleLocationUpdate(dynamic locationData) {
    try {
      print(' SAHArSAHAr Processing location update: $locationData');

      if (locationData is Map<String, dynamic>) {
        String rideId = locationData['rideId'] ?? '';

        if (_currentRideId != null &&
            rideId.toLowerCase() == _currentRideId!.toLowerCase()) {
          double lat =
              double.tryParse(locationData['latitude'].toString()) ?? 0.0;
          double lng =
              double.tryParse(locationData['longitude'].toString()) ?? 0.0;

          if (lat != 0.0 && lng != 0.0) {
            driverLatitude.value = lat;
            driverLongitude.value = lng;
            driverLastUpdate.value = DateTime.now();
            isDriverLocationActive.value = true;

            print(' SAHArSAHAr Driver location updated: ($lat, $lng)');

            _updateDriverLocationWithAnimation(lat, lng);

            if (!isDriverLocationActive.value) {
              if (_isAppInForeground) {
                Get.snackbar(
                  'Driver Located',
                  'Driver is now visible on the map',
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 5),
                );
              }
            }
          } else {
            print(
                ' SAHArSAHAr Invalid coordinates received: lat=$lat, lng=$lng');
          }
        } else {
          print(
              ' SAHArSAHAr Location update for different ride: $rideId vs $_currentRideId');
        }
      } else {
        print(
            ' SAHArSAHAr Invalid location data format: ${locationData.runtimeType}');
      }
    } catch (e) {
      print(' SAHArSAHAr Error handling location update: $e');
    }
  }

  void _updateDriverLocationWithAnimation(double lat, double lng) {
    try {
      final controller = Get.find<RideBookingController>();

      controller.driverLatitude.value = lat;
      controller.driverLongitude.value = lng;
      controller.isDriverLocationActive.value = true;

      String driverName = controller.driverName.value.isNotEmpty
          ? controller.driverName.value
          : 'Driver';

      _mapService.updateDriverMarkerWithAnimation(
        lat,
        lng,
        driverName,
        centerMap: true,
      );
      controller.updateDriverLocation(lat, lng);
      print(
          ' SAHArSAHAr Driver location updated with animation: ($lat, $lng)');
    } catch (e) {
      print(
          ' SAHArSAHAr Error updating driver location with animation: $e');

      try {
        final controller = Get.find<RideBookingController>();
        controller.driverLatitude.value = lat;
        controller.driverLongitude.value = lng;
        controller.isDriverLocationActive.value = true;

        _mapService.updateDriverMarker(lat, lng, 'Driver');
      } catch (fallbackError) {
        print(' SAHArSAHAr Fallback also failed: $fallbackError');
      }
    }
  }

  // ─── Utilities ────────────────────────────────────────────────────

  void setAutoCenter(bool autoCenter) {}

  LatLng? getCurrentDriverLocation() {
    if (driverLatitude.value != 0.0 && driverLongitude.value != 0.0) {
      return LatLng(driverLatitude.value, driverLongitude.value);
    }
    return null;
  }

  bool get isTrackingDriver =>
      isDriverLocationActive.value && _currentRideId != null;

  Duration getTimeSinceLastUpdate() {
    return DateTime.now().difference(driverLastUpdate.value);
  }

  Future<void> centerOnDriverLocation() async {
    LatLng? driverLocation = getCurrentDriverLocation();
    if (driverLocation != null) {
      await _mapService.animateToLocation(driverLocation, zoom: 17.0);
      if (_isAppInForeground) {
        Get.snackbar(
          'Centered',
          'Map centered on driver location',
          duration: const Duration(seconds: 5),
        );
      }
    } else {
      if (_isAppInForeground) {
        Get.snackbar(
          'No Driver Location',
          'Driver location not available',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    await unsubscribeFromRide();
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
    }
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
  String? get currentRideId => _currentRideId;
}
