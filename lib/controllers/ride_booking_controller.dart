import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/core/google_places_service.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/core/map_service.dart';
import 'package:pick_u/core/search_location_service.dart';
import 'package:pick_u/core/sharePref.dart';
import 'package:pick_u/core/signalr_service.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

// Constants
class ApiEndpoints {
  static const String bookRide = '/api/Ride/book';
  static const String startTrip = '/api/Ride/{rideId}/start';
  static const String endTrip = '/api/Ride/{rideId}/end';
  static const String submitTip = '/api/Tip';
  static const String processPayment = '/api/Payment/process';
  static const String fareEstimate = '/api/Ride/fare-estimate';
}

class AppConstants {
  static const String defaultUserId = "44f9ebba-b24d-4df1-8a60-bd7035b6097d";
  static const List<double> tipPercentages = [10.0, 15.0, 20.0];
}

// Enum for ride status
enum RideStatus {
  pending,
  booked,
  waiting,
  driverAssigned,
  driverNear,
  driverArrived,
  tripStarted,
  tripCompleted,
  cancelled,
  noDriver
}

class RideBookingController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Inject services
  final LocationService _locationService = Get.find<LocationService>();
  final SearchService _searchService = Get.find<SearchService>();
  final MapService _mapService = Get.find<MapService>();

  // Text Controllers
  final pickupController = TextEditingController();
  final dropoffController = TextEditingController();
  var stopControllers = <TextEditingController>[].obs;

  // Core ride data
  var pickupLocation = Rx<LocationData?>(null);
  var dropoffLocation = Rx<LocationData?>(null);
  var additionalStops = <LocationData>[].obs;
  var passengerCount = 1.obs;
  var rideType = 'standard'.obs;
  var fareEstimate = 0.0.obs;
  var isMultiStopRide = false.obs;

  // Scheduling variables
  // Fare estimation variables
  var estimatedFare = 0.0.obs;
  var fareMessage = ''.obs;
  var fareCurrency = 'CAD'.obs;
  var isLoadingFare = false.obs;

  var isScheduled = false.obs;
  var scheduledDate = Rx<DateTime?>(null);
  var scheduledTime = Rx<TimeOfDay?>(null);

  // Ride booking state
  var isLoading = false.obs;
  var isRideBooked = false.obs;
  var currentRideId = ''.obs;
  var rideStatus = RideStatus.pending.obs; // Using enum now

  // Driver information
  var driverId = ''.obs;
  var driverName = ''.obs;
  var driverPhone = ''.obs;
  var estimatedPrice = 0.0.obs;
  var vehicle = ''.obs;
  var vehicleColor = ''.obs;

  // Driver location tracking
  final driverLatitude = 0.0.obs;
  final driverLongitude = 0.0.obs;
  final isDriverLocationActive = false.obs;

  // Distance-based notifications
  final hasShownApproachingNotification = false.obs;
  final hasShownArrivedNotification = false.obs;

  // SignalR Service
  late SignalRService signalRService;

  // Audio player for notifications
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    signalRService = Get.put(SignalRService());
    await signalRService.initializeConnection();
  }

  @override
  void onClose() {
    pickupController.dispose();
    dropoffController.dispose();
    for (var controller in stopControllers) {
      controller.dispose();
    }
    super.onClose();
  }

  // Update driver location from SignalR
  void updateDriverLocation(double latitude, double longitude) {
    driverLatitude.value = latitude;
    driverLongitude.value = longitude;
    isDriverLocationActive.value = true;

    print(' SAHArSAHAr Controller: Driver location updated: ($latitude, $longitude)');
    _checkDriverDistanceAndNotify();

    // Trigger map animation through MapService
    String driverDisplayName = driverName.value.isNotEmpty ? driverName.value : 'Driver';
    _mapService.updateDriverMarkerWithAnimation(
      latitude,
      longitude,
      driverDisplayName,
      centerMap: true,
    );
  }

  // Check driver distance and show appropriate notifications
  void _checkDriverDistanceAndNotify() {
    double? distance = getDistanceToDriver();

    // Debug logging
    print('SAHAr Distance Check - Distance: $distance, RideStatus: ${rideStatus.value}');
    print('SAHAr Notification flags - Approaching: ${hasShownApproachingNotification.value}, Arrived: ${hasShownArrivedNotification.value}');

    // Return early if no distance or inappropriate ride status
    if (distance == null) {
      print('SAHAr Distance Check: No distance available');
      return;
    }

    // Only show notifications for these ride statuses
    if (rideStatus.value != RideStatus.driverAssigned &&
        rideStatus.value != RideStatus.driverNear &&
        rideStatus.value != RideStatus.driverArrived &&
        rideStatus.value != RideStatus.waiting &&
        rideStatus.value != RideStatus.booked) {
      print('SAHAr Distance Check: Wrong ride status (${rideStatus.value}) for notifications');
      return;
    }

    print('SAHAr Driver distance: ${distance.round()}m');
    hasShownArrivedNotification.value = false;
    // Show "Driver has arrived" notification (10m or less)
    if (distance <= 10 && !hasShownArrivedNotification.value) {
      print('SAHAr Showing arrived dialog - Distance: ${distance.round()}m');
      hasShownArrivedNotification.value = true;
      rideStatus.value = RideStatus.driverArrived; // Update ride status
      _showDriverArrivedDialog();
      _playNotificationSound(); // Play sound on arrival
    }
    // Show "Driver is approaching" notification (75m or less, but more than 10m)
    else if (distance <= 75 && distance > 10 && !hasShownApproachingNotification.value) {
      print('SAHAr Showing approaching dialog - Distance: ${distance.round()}m');
      hasShownApproachingNotification.value = true;
      rideStatus.value = RideStatus.driverNear; // Update ride status
      _showDriverApproachingDialog();
      _playNotificationSound(); // Play sound on approach
    }
  }

  // Enhanced notification sound system with multiple fallbacks
  Future<void> _playNotificationSound() async {
    bool soundPlayed = false;

    try {
      print('SAHAr: === NOTIFICATION SOUND START ===');

      // Method 1: Try playing asset sound with proper initialization
      try {
        print('SAHAr: Attempting to play asset sound...');
        await _audioPlayer.stop(); // Stop any current playback
        await _audioPlayer.setSource(AssetSource('sounds/notification.mp3'));
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.resume();
        soundPlayed = true;
        print('SAHAr: ✅ Asset sound played successfully');
      } catch (assetError) {
        print('SAHAr: ❌ Asset sound failed: $assetError');
      }

      // Method 2: Try system alert sound if asset failed
      if (!soundPlayed) {
        try {
          print('SAHAr: Trying system alert sound...');
          await SystemSound.play(SystemSoundType.alert);
          soundPlayed = true;
          print('SAHAr: ✅ System alert sound played');
        } catch (systemError) {
          print('SAHAr: ❌ System alert failed: $systemError');
        }
      }

      // Method 3: Try click sound as backup
      if (!soundPlayed) {
        try {
          print('SAHAr: Trying system click sound...');
          await SystemSound.play(SystemSoundType.click);
          soundPlayed = true;
          print('SAHAr: ✅ System click sound played');
        } catch (clickError) {
          print('SAHAr: ❌ System click failed: $clickError');
        }
      }

      // Method 4: Haptic feedback as final fallback
      try {
        print('SAHAr: Adding haptic feedback...');
        await HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 200));
        await HapticFeedback.heavyImpact();
        print('SAHAr: ✅ Haptic feedback completed');
      } catch (hapticError) {
        print('SAHAr: ❌ Haptic feedback failed: $hapticError');
      }

      if (soundPlayed) {
        print('SAHAr: ✅ Notification sound system completed successfully');
      } else {
        print('SAHAr: ⚠️ Sound failed but haptic feedback should work');
      }

    } catch (e) {
      print('SAHAr: 🔥 Critical error in notification sound: $e');
    } finally {
      print('SAHAr: === NOTIFICATION SOUND END ===');
    }
  }

  // Test method to check if sound system works
  Future<void> testNotificationSound() async {
    print('SAHAr: 🧪 Testing notification sound system...');
    await _playNotificationSound();
    Get.snackbar(
      'Sound Test',
      'Check console for sound test results. Did you hear anything?',
      duration: Duration(seconds: 4),
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  // Show driver approaching notification (75m or less)
  void _showDriverApproachingDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              Icons.directions_car_rounded,
              size: 56,
              color: MColor.primaryNavy,
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Driver Approaching!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MColor.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              '${driverName.value.isNotEmpty ? driverName.value : "Your driver"} is getting close to your pickup location.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Please be ready!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Expected arrival info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: MColor.primaryNavy),
                const SizedBox(width: 6),
                Text(
                  'Expected arrival: ${getFormattedDistanceToDriver()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColor.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () => Get.back(),
              child: const Text(
                'Got it!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    // Auto-dismiss after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    });
  }


  // Show driver arrived notification (10m or less)
  void _showDriverArrivedDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: MColor.primaryNavy,
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Driver Has Arrived!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MColor.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              '${driverName.value.isNotEmpty ? driverName.value : "Your driver"} is here and ready to start your ride.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MColor.primaryNavy,
                    side: BorderSide(color: MColor.primaryNavy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => {
                    Get.back(),
                  },
                  child: const Text('Not Yet'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColor.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Get.back();
                    startTrip();
                  },
                  child: const Text('Start Trip'),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  LatLng? getDriverLocation() {
    if (driverLatitude.value != 0.0 && driverLongitude.value != 0.0) {
      return LatLng(driverLatitude.value, driverLongitude.value);
    }
    return null;
  }
  double? getDistanceToDriver() {
    LatLng? userLocation = _locationService.currentLatLng.value;
    LatLng? driverLocation = getDriverLocation();

    if (userLocation != null && driverLocation != null) {
      return _locationService.calculateDistance(userLocation, driverLocation);
    }

    return null;
  }

// Get formatted distance to driver
  String getFormattedDistanceToDriver() {
    double? distance = getDistanceToDriver();
    if (distance != null) {
      if (distance < 1000) {
        return '${distance.round()}m away';
      } else {
        return '${(distance / 1000).toStringAsFixed(1)}km away';
      }
    }
    return 'Distance unknown';
  }

// Clear driver location when ride ends
  void clearDriverLocation() {
    driverLatitude.value = 0.0;
    driverLongitude.value = 0.0;
    isDriverLocationActive.value = false;

    // Reset notification flags when clearing driver location
    hasShownApproachingNotification.value = false;
    hasShownArrivedNotification.value = false;
  }

  // FIXED: Multi-stop management - using proper observable updates
  void addStop() {
    final controller = TextEditingController();
    stopControllers.add(controller);

    additionalStops.add(LocationData(
      address: '',
      latitude: 0,
      longitude: 0,
      stopOrder: additionalStops.length + 2,
    ));

    // Force UI update
    stopControllers.refresh();
    additionalStops.refresh();
    print(' SAHArSAHAr Stop added. Total stops: ${additionalStops.length}');
  }

  void removeStop(int index) {
    if (index >= 0 && index < stopControllers.length) {
      stopControllers[index].dispose();
      stopControllers.removeAt(index);

      if (index < additionalStops.length) {
        additionalStops.removeAt(index);
      }

      // Force UI update
      stopControllers.refresh();
      additionalStops.refresh();
      print(' SAHArSAHAr Stop removed at index $index');
    }
  }

  void setRideType(String type) {
    rideType.value = type;
    isMultiStopRide.value = type == 'Multi-Stop Ride';
  }

  // Delegate to LocationService
  Future<void> setPickupToCurrentLocation() async {
    try {
      await _locationService.getCurrentLocation();
      LocationData? currentLocationData = _locationService.getCurrentLocationData();
      if (currentLocationData != null) {
        pickupController.text = currentLocationData.address;
        pickupLocation.value = currentLocationData;
      } else {
        Get.snackbar('Error', 'Could not get current location');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
    }
  }

  // Core ride booking logic
  Future<void> bookRide() async {
    if (!_validateRideBooking()) return;

    try {
      isLoading.value = true;

      // Create route visualization
      await _mapService.createRouteMarkersAndPolylines(
        pickupLocation: pickupLocation.value,
        dropoffLocation: dropoffLocation.value,
        additionalStops: additionalStops,
      );

      isRideBooked.value = true;
      rideStatus.value = RideStatus.booked;

      String scheduleInfo = _getScheduleInfo();
      Get.snackbar(
        'Success',
        'Route calculated!\nDistance: ${_mapService.routeDistance.value}\nDuration: ${_mapService.routeDuration.value}$scheduleInfo',
        duration: const Duration(seconds: 3),
      );

      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Booking failed: $e');
      isRideBooked.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED: Start ride with proper API structure
  Future<void> startRide() async {
    print(' SAHArSAHAr startRide() called');

    if (!isRideBooked.value) {
      print(' SAHArSAHAr Ride not booked yet');
      Get.snackbar('Error', 'Please book a ride first');
      return;
    }

    if (pickupLocation.value == null || dropoffLocation.value == null) {
      print(' SAHArSAHAr Missing pickup or dropoff location');
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return;
    }

    // Validate scheduled ride requirements
    if (isScheduled.value) {
      if (scheduledDate.value == null || scheduledTime.value == null) {
        Get.snackbar('Incomplete Schedule', 'Please set both date and time');
        return;
      }

      DateTime scheduledDateTime = getScheduledDateTime()!;
      if (scheduledDateTime.isBefore(DateTime.now())) {
        Get.snackbar('Invalid Schedule', 'Scheduled time cannot be in the past');
        return;
      }
    }

    try {
      isLoading.value = true;
      print(' SAHArSAHAr Preparing stops...');

      List<Map<String, dynamic>> allStops = [];

      // Pickup
      allStops.add({
        "stopOrder": 0,
        "location": pickupLocation.value!.address,
        "latitude": pickupLocation.value!.latitude,
        "longitude": pickupLocation.value!.longitude,
      });
      print(' SAHArSAHAr Added pickup: ${pickupLocation.value!.address}');

      // Additional stops
      for (int i = 0; i < additionalStops.length; i++) {
        final stop = additionalStops[i];
        if (stop.address.isNotEmpty) {
          allStops.add({
            "stopOrder": i + 1,
            "location": stop.address,
            "latitude": stop.latitude,
            "longitude": stop.longitude,
          });
          print(' SAHArSAHAr Added stop ${i + 1}: ${stop.address}');
        }
      }

      // Dropoff
      allStops.add({
        "stopOrder": allStops.length,
        "location": dropoffLocation.value!.address,
        "latitude": dropoffLocation.value!.latitude,
        "longitude": dropoffLocation.value!.longitude,
      });
      print(' SAHArSAHAr Added dropoff: ${dropoffLocation.value!.address}');

      DateTime scheduledDateTime = isScheduled.value && getScheduledDateTime() != null
          ? getScheduledDateTime()!
          : DateTime.now();

      var userId = await SharedPrefsService.getUserId() ?? AppConstants.defaultUserId;

      Map<String, dynamic> requestData = {
        "userId": userId,
        "rideType": rideType.value,
        "isScheduled": isScheduled.value,
        "scheduledTime": scheduledDateTime.toIso8601String(),
        "passengerCount": passengerCount.value,
        "fareEstimate": fareEstimate.value,
        "stops": allStops,
      };

      print(' SAHArSAHAr Request payload: $requestData');

      // Set appropriate status based on ride type
      rideStatus.value = isScheduled.value ? RideStatus.waiting : RideStatus.waiting;

      Response response = await _apiProvider.postData(ApiEndpoints.bookRide, requestData);
      print(' SAHArSAHAr API response: ${response.body}');

      if (response.isOk) {
        await _handleRideResponse(response);
      } else {
        rideStatus.value = RideStatus.cancelled;
        Get.snackbar('Error', 'Failed to start ride: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr Exception caught: $e');
      rideStatus.value = RideStatus.cancelled;
      Get.snackbar('Error', 'Failed to start ride: $e');
    } finally {
      isLoading.value = false;
      print(' SAHArSAHAr Ride booking process completed');
    }
  }

  // FIXED: Start trip functionality with proper endpoint
  Future<void> startTrip() async {
    if (currentRideId.value.isEmpty) {
      Get.snackbar('Error', 'Ride ID not found');
      return;
    }

    try {
      isLoading.value = true;

      String endpoint = ApiEndpoints.startTrip.replaceAll('{rideId}', currentRideId.value);
      Response response = await _apiProvider.postData(endpoint, {});

      if (response.isOk) {
        rideStatus.value = RideStatus.tripStarted;
        Get.snackbar('Trip Started', 'Your trip has started successfully!');
      } else {
        Get.snackbar('Error', 'Failed to start trip: ${response.statusText}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to start trip: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED: End trip functionality with proper endpoint
  Future<void> endTrip() async {
    print(' SAHArSAHAr endTrip() method called');
    if (currentRideId.value.isEmpty) {
      Get.snackbar('Error', 'Ride ID not found');
      return;
    }

    try {
      isLoading.value = true;
      print(' SAHArSAHAr Ending trip with ride ID: ${currentRideId.value}');

      String endpoint = ApiEndpoints.endTrip.replaceAll('{rideId}', currentRideId.value);
      Response response = await _apiProvider.postData(endpoint, {});

      if (response.isOk) {
        print(' SAHArSAHAr Trip ended successfully: ${response.body}');
        _handleTripCompletion(response);
      } else {
        print(' SAHArSAHAr Failed to end trip: ${response.statusText}');
        Get.snackbar('Error', 'Failed to end trip: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr Error ending trip: $e');
      Get.snackbar('Error', 'Failed to end trip: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getFareEstimate() async {
    print('SAHArSAHAr getFareEstimate() method called');

    try {
      isLoading.value = true;

      String routeDistanceStr = _mapService.routeDistance.value;
      print('SAHArSAHAr routeDistanceStr: $routeDistanceStr');

      if (routeDistanceStr.isEmpty) {
        print('SAHArSAHAr Route distance is empty');
        return;
      }

      // Extract numeric distance
      String numericPart = routeDistanceStr.split(' ').first;
      double distance = double.tryParse(numericPart) ?? 0.0;
      print('SAHArSAHAr Parsed distance: $distance');

      // Get pickup address
      String address = pickupLocation.value?.address ?? '';
      print('SAHArSAHAr Pickup address: $address');

      if (address.isEmpty) {
        print('SAHArSAHAr Pickup address is empty');
        return;
      }

      // Duration (static for now)
      String duration = "0.0";

      // Build full query string
      String endpoint =
          "${ApiEndpoints.fareEstimate}?Address=${Uri.encodeComponent(address)}&distance=$distance&duration=$duration";

      print('SAHArSAHAr Calling fareEstimate API: $endpoint');

      Response response = await _apiProvider.postData(endpoint,{});

      if (response.isOk) {
        print('SAHArSAHAr Fare estimate response: ${response.body}');

        var responseBody = response.body;
        var fareData = responseBody['fare'] is String
            ? json.decode(responseBody['fare'])
            : responseBody['fare'];

        if (fareData != null && fareData['EstimatedFare'] != null) {
          // Delay update until after build (safe for Obx)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            estimatedFare.value = (fareData['EstimatedFare'] ?? 0.0).toDouble();
            print('SAHArSAHAr Fare updated: ${estimatedFare.value}');
          });
        } else {
          print('SAHArSAHAr No fare data in response');
          Get.snackbar('Error', 'No fare data received');
        }
      } else {
        print('SAHArSAHAr Failed to fetch fare estimate: ${response.statusText}');
        Get.snackbar('Error', 'Failed to fetch fare estimate: ${response.statusText}');
      }
    } catch (e) {
      print('SAHArSAHAr Error in getFareEstimate: $e');
      Get.snackbar('Error', 'Failed to get fare estimate: $e');
    } finally {
      isLoading.value = false;
    }
  }


  // Handle ride booking response
  Future<void> _handleRideResponse(Response response) async {
    try {
      var responseBody = response.body;
      print(' SAHArSAHAr Handling ride response: $responseBody');

      if (responseBody is Map<String, dynamic>) {
        // Handle scheduled rides differently
        if (isScheduled.value) {
          Get.snackbar(
            'Ride Scheduled Successfully!',
            'Your ride has been scheduled for ${DateFormat('MMM dd, yyyy hh:mm a').format(getScheduledDateTime()!)}',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
          );
          clearBooking();
          return;
        }

        // Handle immediate rides - check for different response structures
        String rideIdKey = responseBody.keys.first;
        var rideData = responseBody[rideIdKey];

        if (rideData is Map<String, dynamic>) {
          // Driver found - extract driver information
          currentRideId.value = rideData['rideId'] ?? '';
          driverId.value = rideData['driverId'] ?? '';
          driverName.value = rideData['driverName'] ?? '';
          driverPhone.value = rideData['driverPhone'] ?? '';
          vehicleColor.value = rideData['vehicle'] ?? '';
          vehicle.value = rideData['vehicleColor'] ?? '';
          estimatedPrice.value = (rideData['estimatedPrice'] ?? 0.0).toDouble();
          rideStatus.value = RideStatus.driverAssigned;

          // Set up SignalR subscription for ride updates
          if (currentRideId.value.isNotEmpty) {
            signalRService.subscribeToRide(currentRideId.value);
          }

          Get.snackbar(
              'Driver Assigned!',
              'Driver ${driverName.value} has been assigned to your ride.'
          );
        } else if (rideData is String && rideData.contains('No live drivers available')) {
          // No drivers available
          rideStatus.value = RideStatus.noDriver;
          Get.snackbar(
            'No Drivers Available',
            'No live drivers available right now. Please try again later.',
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      print(' SAHArSAHAr Error handling ride response: $e');
      Get.snackbar('Error', 'Failed to process ride response: $e');
    }
  }

  void _handleTripCompletion(Response response) {
    var responseBody = response.body;
    print(' SAHArSAHAr Processing trip completion response: $responseBody');

    // Always set the status to completed first
    rideStatus.value = RideStatus.tripCompleted;

    if (responseBody is Map<String, dynamic>) {
      // Handle different response structures
      if (responseBody.containsKey('message')) {
        var messageData = responseBody['message'];
        if (messageData is Map<String, dynamic>) {
          _showPaymentDialog(messageData);
          return;
        }
      }

      // Check if response has direct trip data
      if (responseBody.containsKey('finalFare') || responseBody.containsKey('totalFare')) {
        _showPaymentDialog(responseBody);
        return;
      }
    }

    // Fallback if no proper response data
    Get.snackbar('Trip Completed', 'Your trip has ended successfully!');
    _showDefaultPaymentDialog();
  }

  void _showPaymentDialog(Map<String, dynamic> tripData) {
    print(' SAHArSAHAr Showing payment dialog with data: $tripData');

    String rideId = tripData['rideId'] ?? currentRideId.value;
    double finalFare = (tripData['finalFare'] ?? tripData['totalFare'] ?? estimatedPrice.value).toDouble();
    double distance = (tripData['distance'] ?? 0.0).toDouble();
    String rideStartTime = tripData['rideStartTime'] ?? '';
    String rideEndTime = tripData['rideEndTime'] ?? '';
    String duration = tripData['duration'] ?? tripData['totalWaitingTime'] ?? '';

    // Update estimated price with actual final fare from API
    estimatedPrice.value = finalFare;

    _showPaymentPopup(
      rideId: rideId,
      finalFare: finalFare,
      distance: distance,
      duration: duration,
      rideStartTime: rideStartTime,
      rideEndTime: rideEndTime,
    );
  }

  // Enhanced payment methods with better UI
  void _showPaymentPopup({
    required String rideId,
    required double finalFare,
    required double distance,
    required String duration,
    required String rideStartTime,
    required String rideEndTime,
    String? totalWaitingTime,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: MColor.primaryNavy, size: 28),
            SizedBox(width: 8),
            Text('Trip Completed!', style: TextStyle(color: MColor.primaryNavy, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Summary Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    _buildSummaryRow('Distance', distance > 0 ? '${distance.toStringAsFixed(2)} km' : 'N/A'),
                    SizedBox(height: 8),
                    _buildSummaryRow('Duration', totalWaitingTime ?? 'N/A'),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Fare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('\$${finalFare.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MColor.primaryNavy)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          // Payment buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColor.primaryNavy,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Get.back();
                    _completePayment(finalFare);
                  },
                  child: Text('Pay \$${finalFare.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: MColor.primaryNavy),
                  ),
                  onPressed: () {
                    Get.back();
                    _showTipDialog(finalFare);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 8),
                      Text('Add Tip', style: TextStyle(color: MColor.primaryNavy, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showTipDialog(double finalFare) {
    RxDouble selectedTip = 0.0.obs;
    List<double> tipOptions = AppConstants.tipPercentages;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            SizedBox(width: 8),
            Text('Add Tip', style: TextStyle(color: MColor.primaryNavy, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show your appreciation to ${driverName.value}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),

              // Tip amount display
              Obx(() => Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MColor.primaryNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Fare: \$${finalFare.toStringAsFixed(2)}'),
                    if (selectedTip.value > 0)
                      Text('Tip: \$${selectedTip.value.toStringAsFixed(2)}',
                          style: TextStyle(color: MColor.primaryNavy)),
                    Divider(),
                    Text('Total: \$${(finalFare + selectedTip.value).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),

              SizedBox(height: 20),

              // Tip options
              Text('Select tip amount:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              Obx(() => Wrap(
                spacing: 8,
                children: tipOptions.map((tip) =>
                    ChoiceChip(
                      label: Text('\$${tip.toStringAsFixed(0)}'),
                      selected: selectedTip.value == tip,
                      onSelected: (selected) {
                        if (selected) selectedTip.value = tip;
                      },
                      selectedColor: MColor.primaryNavy.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: selectedTip.value == tip ? MColor.primaryNavy : Colors.black,
                        fontWeight: selectedTip.value == tip ? FontWeight.bold : FontWeight.normal,
                      ),
                    )
                ).toList(),
              )),

              SizedBox(height: 16),

              // Custom tip input
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Custom tip amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MColor.primaryNavy),
                  ),
                  labelStyle: TextStyle(color: MColor.primaryNavy),
                ),
                onChanged: (value) {
                  double? customTip = double.tryParse(value);
                  if (customTip != null && customTip >= 0) {
                    selectedTip.value = customTip;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _completePayment(finalFare);
            },
            child: Text('Skip Tip', style: TextStyle(color: MColor.primaryNavy)),
          ),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MColor.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Get.back();
              double totalAmount = finalFare + selectedTip.value;
              if (selectedTip.value > 0) {
                await _submitTip(selectedTip.value, finalFare, totalAmount);
              }
              await _completePayment(totalAmount);
            },
            child: Text('Pay \$${(finalFare + selectedTip.value).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Enhanced payment methods with API integration
  Future<void> _completePayment(double amount) async {
    try {
      isLoading.value = true;
      var userId = await SharedPrefsService.getUserId() ?? AppConstants.defaultUserId;

      // Calculate tip amount
      double tipAmount = amount - estimatedPrice.value;

      Map<String, dynamic> paymentData = {
        "rideId": currentRideId.value,
        "userId": userId,
        "totalAmount": amount,
        "fareAmount": estimatedPrice.value,
        "tipAmount": tipAmount,
        "paymentMethod": "digital",
      };

      print(' SAHArSAHAr Processing payment: $paymentData');

      // Call payment API
      Response response = await _apiProvider.postData(ApiEndpoints.processPayment, paymentData);

      if (response.isOk) {
        print(' SAHArSAHAr Payment processed successfully: ${response.body}');

        Get.snackbar(
          'Payment Successful!',
          'Payment of \$${amount.toStringAsFixed(2)} completed successfully!${tipAmount > 0 ? '\nTip of \$${tipAmount.toStringAsFixed(2)} added for ${driverName.value}!' : ''}',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        clearBooking();
      } else {
        print(' SAHArSAHAr Payment failed: ${response.statusText}');
        Get.snackbar('Payment Failed', 'Failed to process payment: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr Error processing payment: $e');
      Get.snackbar('Payment Error', 'Failed to process payment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED: Submit tip with proper API structure
  Future<void> _submitTip(double tipAmount, double finalFare, double totalAmount) async {
    print(' SAHArSAHAr 🟡 _submitTip() called');
    print(' SAHArSAHAr 💰 Tip Amount: \$${tipAmount.toStringAsFixed(2)}');
    print(' SAHArSAHAr 🧾 Final Fare: \$${finalFare.toStringAsFixed(2)}');
    print(' SAHArSAHAr 📊 Total Amount: \$${totalAmount.toStringAsFixed(2)}');

    try {
      isLoading.value = true;
      print(' SAHArSAHAr ⏳ isLoading set to true');

      var userId = await SharedPrefsService.getUserId() ?? AppConstants.defaultUserId;

      Map<String, dynamic> tipData = {
        "rideId": currentRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "amount": tipAmount,
        "createdAt": DateTime.now().toIso8601String(),
      };

      print(' SAHArSAHAr 📦 Tip Payload: $tipData');

      Response response = await _apiProvider.postData(ApiEndpoints.submitTip, tipData);
      print(' SAHArSAHAr 📥 API Response: ${response.body}');

      if (response.isOk) {
        print(' SAHArSAHAr ✅ Tip submitted successfully');
        Get.snackbar(
          'Tip Added!',
          'Tip of \$${tipAmount.toStringAsFixed(2)} added for ${driverName.value}!',
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        print(' SAHArSAHAr ❌ Tip submission failed: ${response.statusText}');
        Get.snackbar('Error', 'Failed to process tip: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr 🔥 Exception during tip submission: $e');
      Get.snackbar('Error', 'Failed to process tip: $e');
    } finally {
      isLoading.value = false;
      print(' SAHArSAHAr ✅ isLoading set to false');
    }
  }

  // Validation methods
  bool _validateRideBooking() {
    if (pickupLocation.value == null || dropoffLocation.value == null) {
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return false;
    }

    if (isScheduled.value) {
      if (scheduledDate.value == null || scheduledTime.value == null) {
        Get.snackbar('Error', 'Please select both date and time for scheduled ride');
        return false;
      }

      DateTime scheduledDateTime = getScheduledDateTime()!;
      if (scheduledDateTime.isBefore(DateTime.now())) {
        Get.snackbar('Error', 'Scheduled time cannot be in the past');
        return false;
      }
    }

    return true;
  }

  String _getScheduleInfo() {
    if (isScheduled.value && scheduledDate.value != null && scheduledTime.value != null) {
      DateTime scheduledDateTime = getScheduledDateTime()!;
      return '\nScheduled: ${DateFormat('MMM dd, yyyy hh:mm a').format(scheduledDateTime)}';
    }
    return '';
  }

  // Delegate to SearchService
  Future<void> searchLocation(String query, String fieldType) async {
    await _searchService.searchLocation(query, fieldType);
  }

  // Handle search suggestion selection
  Future<void> selectSuggestion(AutocompletePrediction prediction) async {
    try {
      isLoading.value = true;
      _searchService.searchSuggestions.clear();

      PlaceDetails? placeDetails = await _searchService.getPlaceDetails(prediction.placeId);
      if (placeDetails == null) return;

      String activeField = _searchService.activeSearchField.value;

      if (activeField == 'pickup') {
        _setPickupLocation(placeDetails);
      } else if (activeField == 'dropoff') {
        _setDropoffLocation(placeDetails);
      } else if (activeField.startsWith('stop_')) {
        _setStopLocation(activeField, placeDetails);
      }

      _searchService.activeSearchField.value = '';
    } catch (e) {
      Get.snackbar('Error', 'Failed to select location');
    } finally {
      isLoading.value = false;
    }
  }

  void _setPickupLocation(PlaceDetails placeDetails) {
    pickupController.text = placeDetails.formattedAddress;
    pickupLocation.value = LocationData(
      address: placeDetails.formattedAddress,
      latitude: placeDetails.location.latitude,
      longitude: placeDetails.location.longitude,
      stopOrder: 0,
    );
  }

  void _setDropoffLocation(PlaceDetails placeDetails) {
    dropoffController.text = placeDetails.formattedAddress;
    dropoffLocation.value = LocationData(
      address: placeDetails.formattedAddress,
      latitude: placeDetails.location.latitude,
      longitude: placeDetails.location.longitude,
      stopOrder: 1,
    );
  }

  void _setStopLocation(String activeField, PlaceDetails placeDetails) {
    int stopIndex = int.parse(activeField.split('_')[1]);
    if (stopIndex < stopControllers.length) {
      stopControllers[stopIndex].text = placeDetails.formattedAddress;

      LocationData stopData = LocationData(
        address: placeDetails.formattedAddress,
        latitude: placeDetails.location.latitude,
        longitude: placeDetails.location.longitude,
        stopOrder: stopIndex + 2,
      );

      if (stopIndex < additionalStops.length) {
        additionalStops[stopIndex] = stopData;
      } else {
        additionalStops.add(stopData);
      }
    }
  }

  // Scheduling
  void toggleScheduling() {
    isScheduled.value = !isScheduled.value;
    if (!isScheduled.value) {
      scheduledDate.value = null;
      scheduledTime.value = null;
    }
  }

  void setScheduledDate(DateTime date) => scheduledDate.value = date;
  void setScheduledTime(TimeOfDay time) => scheduledTime.value = time;

  DateTime? getScheduledDateTime() {
    if (scheduledDate.value != null && scheduledTime.value != null) {
      return DateTime(
        scheduledDate.value!.year,
        scheduledDate.value!.month,
        scheduledDate.value!.day,
        scheduledTime.value!.hour,
        scheduledTime.value!.minute,
      );
    }
    return null;
  }

  // Delegate to MapService
  void setMapController(GoogleMapController controller) {
    _mapService.setMapController(controller);
  }

  Future<void> showPickupLocationWithZoom() async {
    await _mapService.showPickupLocationWithZoom(pickupLocation.value);
  }

  Future<void> centerOnCurrentLocation() async {
    LatLng? currentLatLng = _locationService.currentLatLng.value;
    if (currentLatLng != null) {
      await _mapService.animateToLocation(currentLatLng);
      Get.snackbar('Current Location', 'Centered on your location');
    }
  }

  // Cleanup and reset
  void resetForm() {
    pickupController.clear();
    dropoffController.clear();
    for (var controller in stopControllers) {
      controller.dispose();
    }
    stopControllers.clear();
    additionalStops.clear();
    pickupLocation.value = null;
    dropoffLocation.value = null;
    passengerCount.value = 1;
    _searchService.clearSearchResults();
    currentRideId.value = '';
    rideStatus.value = RideStatus.pending;
    isScheduled.value = false;
    scheduledDate.value = null;
    scheduledTime.value = null;
    signalRService.unsubscribeFromRide();
    isRideBooked.value = false;
    driverLatitude.value = 0.0;
    driverLongitude.value = 0.0;
    isDriverLocationActive.value = false;
  }

  void clearBooking() {
    _mapService.clearMap();
    isRideBooked.value = false;
    resetForm();
    _locationService.getCurrentLocation();

    // Reset notification flags for next ride
    hasShownApproachingNotification.value = false;
    hasShownArrivedNotification.value = false;
  }

  void _showDefaultPaymentDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Trip Completed!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your trip has been completed successfully!',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Fare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${estimatedPrice.value.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Get.back();
                _completePayment(estimatedPrice.value);
              },
              child: Text('Pay \$${estimatedPrice.value.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Getters that delegate to services
  List<AutocompletePrediction> get searchSuggestions => _searchService.searchSuggestions;
  bool get isSearching => _searchService.isSearching.value;
  String get activeSearchField => _searchService.activeSearchField.value;
  Set<Marker> get markers => _mapService.markers;
  Set<Polyline> get polylines => _mapService.polylines;
  String get routeDistance => _mapService.routeDistance.value;
  String get routeDuration => _mapService.routeDuration.value;
  bool get isLoadingRoute => _mapService.isLoadingRoute.value;
}
