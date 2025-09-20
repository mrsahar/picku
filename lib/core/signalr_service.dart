// Create a new file: services/signalr_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/core/map_service.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:get/get.dart';

import 'dart:async';
import 'package:get/get.dart';

class SignalRService extends GetxService {
  static const String hubUrl = 'http://pickurides.com/rideHub';

  HubConnection? _connection;
  bool _isConnected = false;
  String? _currentRideId;

  // Observables for driver location
  final driverLatitude = 0.0.obs;
  final driverLongitude = 0.0.obs;
  final driverLastUpdate = DateTime.now().obs;
  final isDriverLocationActive = false.obs;

  // Get MapService instance
  MapService get _mapService => Get.find<MapService>();

  Future<void> initializeConnection() async {
    try {
      _connection = HubConnectionBuilder()
          .withUrl(hubUrl)
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
      });

      _connection!.onreconnecting((error) {
        print(' SAHAr SignalR: Reconnecting: $error');
      });

      _connection!.onreconnected((connectionId) {
        print(' SAHAr SignalR: Reconnected with ID: $connectionId');
        _isConnected = true;
        // Re-subscribe to ride if we have one
        if (_currentRideId != null) {
          subscribeToRide(_currentRideId!);
        }
      });

      await _connection!.start();
      _isConnected = true;
      print(' SAHAr SignalR: Successfully connected to RideHub');

    } catch (e) {
      print(' SAHAr SignalR: Failed to connect: $e');
      _isConnected = false;
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

      Get.snackbar(
        'Tracking Active',
        'Now tracking driver location',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
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

  void _handleRideStatusUpdate(dynamic rideData) {
    try {
      print(' SAHAr Processing ride status update: $rideData');
      final controller = Get.find<RideBookingController>();

      if (rideData is Map<String, dynamic>) {
        RideStatus status = rideData['rideStatus'] ?? '';
        controller.rideStatus.value = status;

        if (status == 'Started') {
          Get.snackbar('Trip Started', 'Your driver has started the trip!');
        } else if (status == 'Completed') {
          Get.snackbar('Trip Completed', 'You have reached your destination');
          unsubscribeFromRide();
        }
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
                duration: const Duration(seconds: 2),
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
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'No Driver Location',
        'Driver location not available',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> dispose() async {
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
