// Create a new file: services/signalr_service.dart
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:get/get.dart';

class SignalRService extends GetxService {
  static const String hubUrl = 'http://sahilsally9-001-site1.qtempurl.com/rideHub';

  HubConnection? _connection;
  bool _isConnected = false;
  String? _currentRideId;

  // Observables for driver location
  final driverLatitude = 0.0.obs;
  final driverLongitude = 0.0.obs;
  final driverLastUpdate = DateTime.now().obs;
  final isDriverLocationActive = false.obs;

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
      print('Processing location update: $locationData');

      if (locationData is Map<String, dynamic>) {
        String rideId = locationData['rideId'] ?? '';

        // Check if this location update is for our current ride
        if (_currentRideId != null &&
            rideId.toLowerCase() == _currentRideId!.toLowerCase()) {

          double lat = double.tryParse(locationData['latitude'].toString()) ?? 0.0;
          double lng = double.tryParse(locationData['longitude'].toString()) ?? 0.0;

          if (lat != 0.0 && lng != 0.0) {
            driverLatitude.value = lat;
            driverLongitude.value = lng;
            driverLastUpdate.value = DateTime.now();

            print('Driver location updated: ($lat, $lng)');

            // Update driver location on map through controller
            _updateDriverLocationOnMap(lat, lng);

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
            print('Invalid coordinates received: lat=$lat, lng=$lng');
          }
        } else {
          print('Location update for different ride: $rideId vs $_currentRideId');
        }
      } else {
        print('Invalid location data format: ${locationData.runtimeType}');
      }
    } catch (e) {
      print('Error handling location update: $e');
    }
  }

  void _updateDriverLocationOnMap(double lat, double lng) {
    try {
      final controller = Get.find<RideBookingController>();
      // Directly update the driver location observables
      controller.driverLatitude.value = lat;
      controller.driverLongitude.value = lng;
      controller.isDriverLocationActive.value = true;

      print(' SAHAr SignalR: Driver location updated through controller: ($lat, $lng)');
    } catch (e) {
      print(' SAHAr Error updating driver location on map: $e');
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
