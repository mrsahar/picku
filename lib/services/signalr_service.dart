// Create a new file: services/signalr_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/services/map_service.dart';
import 'package:pick_u/services/global_variables.dart';
import 'package:signalr_core/signalr_core.dart';

enum SignalRConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

class SignalRService extends GetxService {
  static SignalRService get to => Get.find<SignalRService>();

  static const String hubUrl = 'http://pickurides.com/ridechathub';
  static const Duration retryInterval = Duration(seconds: 5);

  HubConnection? _connection;
  bool _isConnected = false;
  String? _currentRideId;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 10; // Maximum retry attempts before backing off

  // Public getter for connection (used by ChatBackgroundService)
  HubConnection? get connection => _connection;

  // Connection status observable
  final connectionStatus = SignalRConnectionStatus.disconnected.obs;

  // Observables for driver location
  final driverLatitude = 0.0.obs;
  final driverLongitude = 0.0.obs;
  final driverLastUpdate = DateTime.now().obs;
  final isDriverLocationActive = false.obs;

  // Get MapService instance
  MapService get _mapService => Get.find<MapService>();

  // Get GlobalVariables instance for JWT token
  GlobalVariables get _globalVars => GlobalVariables.instance;

  @override
  void onInit() {
    super.onInit();
    // Auto-initialize connection when service is created
    print(' SAHAr SignalR: Service initialized, starting connection...');
    initializeConnection();
  }

  @override
  void onClose() {
    // Clean up when service is disposed (app closing)
    print(' SAHAr SignalR: Service closing, cleaning up connection...');
    _retryTimer?.cancel();
    dispose();
    super.onClose();
  }

  Future<void> initializeConnection() async {
    try {
      connectionStatus.value = SignalRConnectionStatus.connecting;

      // Get JWT token from GlobalVariables
      final token = _globalVars.userToken;

      // Build connection with JWT authorization
      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
              //logging: (level, message) => print(' SAHAr SignalR Log: $message'),
            ),
          )
          .withAutomaticReconnect([1000, 2000, 5000, 10000, 30000]) // Built-in retry with backoff
          .build();

      // Listen for ride status changes
      _connection!.on('RideStatusChanged', (message) {
        print(' SAHAr SignalR: Ride Status Changed: $message');
        if (message != null && message.isNotEmpty) {
          _handleRideStatusUpdate(message[0]);
        }
      });

      // Listen for driver location updates
      _connection!.on('ReceiveRideLocation', (message) {
        print(' SAHAr SignalR: Received Location: $message');
        if (message != null && message.isNotEmpty) {
          _handleLocationUpdate(message[0]);
        }
      });

      // Connection state listeners
      _connection!.onclose((error) {
        print(' SAHAr SignalR: Connection closed: $error');
        _isConnected = false;
        isDriverLocationActive.value = false;
        connectionStatus.value = SignalRConnectionStatus.disconnected;
        _startRetryTimer();
      });

      _connection!.onreconnecting((error) {
        print(' SAHAr SignalR: Reconnecting: $error');
        connectionStatus.value = SignalRConnectionStatus.reconnecting;
      });

      _connection!.onreconnected((connectionId) {
        print(' SAHAr SignalR: Reconnected with ID: $connectionId');
        _isConnected = true;
        connectionStatus.value = SignalRConnectionStatus.connected;
        _retryAttempts = 0; // Reset retry attempts on successful connection
        _retryTimer?.cancel();

        // Re-subscribe to ride if we have one
        if (_currentRideId != null) {
          subscribeToRide(_currentRideId!);
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
      print(' SAHAr SignalR: Starting retry timer (attempt $_retryAttempts/$maxRetryAttempts)');

      _retryTimer = Timer(retryInterval, () {
        if (!_isConnected) {
          print(' SAHAr SignalR: Retrying connection...');
          initializeConnection();
        }
      });
    } else {
      print(' SAHAr SignalR: Max retry attempts reached, backing off');
      connectionStatus.value = SignalRConnectionStatus.error;

      // Start a longer interval timer for periodic retry attempts
      _retryTimer = Timer(const Duration(minutes: 1), () {
        _retryAttempts = 0; // Reset counter for new attempt cycle
        _startRetryTimer();
      });
    }
  }

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
    } catch (e) {
      print(' SAHAr SignalR: Failed to subscribe to ride: $e');
    }
  }

  Future<void> unsubscribeFromRide() async {
    if (!_isConnected || _connection == null || _currentRideId == null) {
      return;
    }

    try {
      await _connection!.invoke('UnsubscribeFromRide', args: [_currentRideId!]);
      _currentRideId = null;
      isDriverLocationActive.value = false;
      print(' SAHAr SignalR: Unsubscribed from ride');
    } catch (e) {
      print(' SAHAr SignalR: Failed to unsubscribe: $e');
    }
  }

  // Manual retry method that can be called from UI
  Future<void> retryConnection() async {
    _retryTimer?.cancel();
    _retryAttempts = 0;
    await initializeConnection();
  }

  void _handleRideStatusUpdate(dynamic rideData) {
    try {
      print(' SAHAr Processing ride status update: $rideData');
      final controller = Get.find<RideBookingController>();

      if (rideData is Map<String, dynamic>) {
        String statusString = (rideData['status'] ?? rideData['rideStatus'] ?? '').toString();

        // Convert string status to RideStatus enum
        RideStatus status;
        switch (statusString.toLowerCase()) {
          case 'pending':
            status = RideStatus.pending;
            break;
          case 'in-progress':
          case 'inprogress':
          case 'started':
            status = RideStatus.tripStarted;
            controller.rideStatus.value = status;
            Get.snackbar('Trip Started', 'Your driver has started the trip!',
                backgroundColor: Colors.green.withValues(alpha: 0.8),
                colorText: Colors.white);
            break;
          case 'completed':
            status = RideStatus.tripCompleted;
            controller.rideStatus.value = status;
            Get.snackbar('Trip Completed', 'You have reached your destination',
                backgroundColor: Colors.blue.withValues(alpha: 0.8),
                colorText: Colors.white);
            unsubscribeFromRide();
            break;
          case 'cancelled':
            status = RideStatus.cancelled;
            controller.rideStatus.value = status;
            unsubscribeFromRide();
            break;
          default:
            print(' SAHAr Unknown status: $statusString');
            return;
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

        // Check if this location update is for our current ride
        if (_currentRideId != null &&
            rideId.toLowerCase() == _currentRideId!.toLowerCase()) {

          double lat = double.tryParse(locationData['latitude'].toString()) ?? 0.0;
          double lng = double.tryParse(locationData['longitude'].toString()) ?? 0.0;

          if (lat != 0.0 && lng != 0.0) {
            // Update observables
            driverLatitude.value = lat;
            driverLongitude.value = lng;
            driverLastUpdate.value = DateTime.now();
            isDriverLocationActive.value = true;

            print(' SAHArSAHAr Driver location updated: ($lat, $lng)');

            // Update driver location with smooth animation and auto-centering
            _updateDriverLocationWithAnimation(lat, lng);

            // Show notification for first location update
            if (!isDriverLocationActive.value) {
              Get.snackbar(
                'Driver Located',
                'Driver is now visible on the map',
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 5),
              );
            }
          } else {
            print(' SAHArSAHAr Invalid coordinates received: lat=$lat, lng=$lng');
          }
        } else {
          print(' SAHArSAHAr Location update for different ride: $rideId vs $_currentRideId');
        }
      } else {
        print(' SAHArSAHAr Invalid location data format: ${locationData.runtimeType}');
      }
    } catch (e) {
      print(' SAHArSAHAr Error handling location update: $e');
    }
  }

  /// Enhanced method to update driver location with animation and auto-centering
  void _updateDriverLocationWithAnimation(double lat, double lng) {
    try {
      final controller = Get.find<RideBookingController>();

      // Update controller observables (for backward compatibility)
      controller.driverLatitude.value = lat;
      controller.driverLongitude.value = lng;
      controller.isDriverLocationActive.value = true;

      // Get driver name from controller
      String driverName = controller.driverName.value.isNotEmpty
          ? controller.driverName.value
          : 'Driver';

      // Use MapService to create animated driver marker with auto-centering
      _mapService.updateDriverMarkerWithAnimation(
        lat,
        lng,
        driverName,
        centerMap: true, // Auto-center map on driver
      );
      controller.updateDriverLocation(lat, lng);
      print(' SAHArSAHAr Driver location updated with animation: ($lat, $lng)');
    } catch (e) {
      print(' SAHArSAHAr Error updating driver location with animation: $e');

      // Fallback to basic marker update
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

  /// Enable/disable automatic map centering on driver location updates
  void setAutoCenter(bool autoCenter) {
    // This method can be used to control auto-centering behavior
    // For now, we always auto-center, but this provides flexibility
  }

  /// Get current driver location as LatLng
  LatLng? getCurrentDriverLocation() {
    if (driverLatitude.value != 0.0 && driverLongitude.value != 0.0) {
      return LatLng(driverLatitude.value, driverLongitude.value);
    }
    return null;
  }

  /// Check if driver location is being actively tracked
  bool get isTrackingDriver => isDriverLocationActive.value && _currentRideId != null;

  /// Get time since last location update
  Duration getTimeSinceLastUpdate() {
    return DateTime.now().difference(driverLastUpdate.value);
  }

  /// Force center map on current driver location
  Future<void> centerOnDriverLocation() async {
    LatLng? driverLocation = getCurrentDriverLocation();
    if (driverLocation != null) {
      await _mapService.animateToLocation(driverLocation, zoom: 16.0);
      Get.snackbar(
        'Centered',
        'Map centered on driver location',
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        'No Driver Location',
        'Driver location not available',
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Dispose method to clean up resources
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
