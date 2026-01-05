import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/services/google_places_service.dart';
import 'package:pick_u/services/location_service.dart';
import 'package:pick_u/services/map_service.dart';
import 'package:pick_u/services/payment_service.dart';
import 'package:pick_u/services/search_location_service.dart';
import 'package:pick_u/services/share_pref.dart';
import 'package:pick_u/services/signalr_service.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

// Constants
class ApiEndpoints {
  static const String bookRide = '/api/Ride/book';
  static const String startTrip = '/api/Ride/{rideId}/start';
  static const String endTrip = '/api/Ride/{rideId}/end';
  static const String submitTip = '/api/Tip';
  static const String processPayment = '/api/Payment/customer-payments';
  static const String fareEstimate = '/api/Ride/fare-estimate';
  static const String submitFeedback = '/api/Feedback';
  static const String saveHeldPayment = '/api/Payment/held-payments';
  static const String completeTransaction = '/api/Payment/complete-transaction';
  static const String cancelRide = '/api/Payment/cancel-ride';
}

class AppConstants {
  static const String defaultUserId = "44f9ebba-b24d-4df1-8a60-bd7035b6097d";
  static const List<double> tipPercentages = [10.0, 15.0, 20.0];
  static const String defaultUserName = "Name";
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

  // Reactive text values for UI updates
  var pickupText = ''.obs;
  var dropoffText = ''.obs;

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
  String _lastFareEstimateKey = ''; // Track last fare estimate request
  bool _hasShownServiceUnavailable = false; // Prevent duplicate snackbars

  var isScheduled = false.obs;
  var scheduledDate = Rx<DateTime?>(null);
  var scheduledTime = Rx<TimeOfDay?>(null);

  // Ride booking state
  var isLoading = false.obs;
  var isRideBooked = false.obs;
  var currentRideId = ''.obs;
  var prevRideId = ''.obs;
  var rideStatus = RideStatus.pending.obs; // Using enum now

  // Driver information
  var driverId = ''.obs;
  var driverName = ''.obs;
  var driverPhone = ''.obs;
  var estimatedPrice = 0.0.obs;
  var actualFareBeforeBalance = 0.0.obs; // Store actual fare before balance deduction
  var vehicle = ''.obs;
  var vehicleColor = ''.obs;
  var rating = 0.0.obs;
  var driverStripeAccountId = ''.obs; // Driver's Stripe Connected Account ID

  // Driver location tracking
  final driverLatitude = 0.0.obs;
  final driverLongitude = 0.0.obs;
  final isDriverLocationActive = false.obs;

  // Store payment intent ID when ride is booked
  RxString heldPaymentIntentId = ''. obs;
  // Store the amount that was held for payment
  double _heldAmount = 0.0;
  // Store selected tip amount
  var selectedTipAmount = 0.0.obs;
  // Store payment dialog data for re-opening
  Map<String, dynamic>? _paymentDialogData;
  // Ride duration display for payment popup
  var rideDurationDisplay = 'Calculating...'.obs;

  // Distance tracking for destination (when trip started)
  final distanceToDestination = 0.0.obs;
  final isTrackingDestination = false.obs;

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
    _setupLocationListener();
    _setupTextControllerListeners();
  }

  void _setupTextControllerListeners() {
    // Listen to pickup text controller changes
    pickupController.addListener(() {
      pickupText.value = pickupController.text;
    });

    // Listen to dropoff text controller changes
    dropoffController.addListener(() {
      dropoffText.value = dropoffController.text;
    });
  }

  Future<void> _initializeServices() async {
    signalRService = Get.put(SignalRService());
    await signalRService.initializeConnection();
  }

  void _setupLocationListener() {
    // Listen to user location changes to update distance to destination when trip is started
    ever(_locationService.currentLatLng, (LatLng? newLocation) {
      if (newLocation != null && isTrackingDestination.value) {
        _updateDistanceToDestination();
      }
    });
  }

  void _updateDistanceToDestination() {
    if (dropoffLocation.value != null && _locationService.currentLatLng.value != null) {
      LatLng userLocation = _locationService.currentLatLng.value!;
      LatLng destinationLocation = LatLng(
        dropoffLocation.value!.latitude,
        dropoffLocation.value!.longitude,
      );

      double distance = _locationService.calculateDistance(userLocation, destinationLocation);
      distanceToDestination.value = distance;

      print(' SAHAr Distance to destination updated: ${distance.round()}m');
    }
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

  // Play notification sound

  Future<void> _playNotificationSound() async {
    try {
      // Play a short sound for notifications
      await _audioPlayer.setSource(AssetSource('sounds/notification.mp3'));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.resume();
      _startVibration();
    } catch (e) {
      print('SAHAr Error playing notification sound: $e');
    }
  }
  Future<void> _startVibration() async {
    try {
      for (int i = 0; i < 6; i++) {
        HapticFeedback.heavyImpact(); // Strong vibration
        await Future.delayed(const Duration(milliseconds: 500));
      }
      print('SAHAr Vibration pattern completed (3 seconds)');
    } catch (e) {
      print('SAHAr Error starting vibration: $e');
    }
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
                  child: const Text('Start Ride'),
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
    // When trip has started, show distance to destination instead of driver
    if (rideStatus.value == RideStatus.tripStarted && isTrackingDestination.value) {
      if (distanceToDestination.value > 0) {
        double distance = distanceToDestination.value;
        if (distance < 1000) {
          return '${distance.round()}m remaining';
        } else {
          return '${(distance / 1000).toStringAsFixed(1)} km remaining';
        }
      } else {
        return 'Calculating distance...';
      }
    }

    // Default behavior - show distance to driver
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

        // Reset fare estimation tracking when pickup location changes
        _lastFareEstimateKey = '';
        _hasShownServiceUnavailable = false;
      } else {
        //Get.snackbar('Error', 'Could not get current location');
      }
    } catch (e) {
      // Get.snackbar('Error', 'Failed to get current location: $e');
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
        duration: const Duration(seconds: 5),
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
  Future<void> startRide([String? paymentToken]) async {
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
        "paymentToken": paymentToken,
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

        // Enable destination tracking when trip starts
        isTrackingDestination.value = true;
        _updateDistanceToDestination(); // Calculate initial distance

        Get.snackbar('Trip Started', 'Your trip has started successfully!');
        print(' SAHAr Trip started - destination tracking enabled');
      } else {
        Get.snackbar('Error', 'Failed to Start Ride: ${response.statusText}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to Start Ride: $e');
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
        prevRideId.value = currentRideId.value;
        _handleTripCompletion(response);
      } else {
        print(' SAHArSAHAr Failed to end trip: ${response.statusText}');
        Get.snackbar('Error', 'Failed to End Ride: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr Error ending trip: $e');
      Get.snackbar('Error', 'Failed to End Ride: $e');
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

        // Check if fare contains error message
        if (responseBody['fare'] is String &&
            responseBody['fare'].toString().contains('Fare settings not found')) {
          print('SAHArSAHAr Fare settings not found for this location');
          estimatedFare.value = 0.0;

          // Only show snackbar if we haven't shown it for this location
          if (!_hasShownServiceUnavailable) {
            _hasShownServiceUnavailable = true;
            Get.snackbar(
              'Service Unavailable',
              'Service is unavailable in your area',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }
          return;
        }

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
      //Get.snackbar('Error', 'Failed to get fare estimate: $e');
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
          // Extract rideId from response for scheduled rides
          // Handle nested structure where rideId might be a Map containing the ride data
          String? scheduledRideId;
          
          if (responseBody.containsKey('rideId')) {
            final rideIdValue = responseBody['rideId'];
            // Check if rideId is a Map (nested structure)
            if (rideIdValue is Map<String, dynamic>) {
              scheduledRideId = rideIdValue['rideId'] as String?;
              scheduledRideId ??= rideIdValue['id'] as String?;
              scheduledRideId ??= rideIdValue['scheduledRideId'] as String?;
            } else if (rideIdValue is String) {
              scheduledRideId = rideIdValue;
            }
          } else if (responseBody.containsKey('id')) {
            final idValue = responseBody['id'];
            if (idValue is Map<String, dynamic>) {
              scheduledRideId = idValue['rideId'] as String?;
              scheduledRideId ??= idValue['id'] as String?;
            } else if (idValue is String) {
              scheduledRideId = idValue;
            }
          } else if (responseBody.containsKey('scheduledRideId')) {
            final scheduledRideIdValue = responseBody['scheduledRideId'];
            if (scheduledRideIdValue is Map<String, dynamic>) {
              scheduledRideId = scheduledRideIdValue['rideId'] as String?;
              scheduledRideId ??= scheduledRideIdValue['id'] as String?;
            } else if (scheduledRideIdValue is String) {
              scheduledRideId = scheduledRideIdValue;
            }
          } else if (responseBody.keys.isNotEmpty) {
            // Try to get rideId from first key's value
            final firstKey = responseBody.keys.first;
            final firstValue = responseBody[firstKey];
            if (firstValue is Map<String, dynamic>) {
              scheduledRideId = firstValue['rideId'] as String?;
              scheduledRideId ??= firstValue['id'] as String?;
              scheduledRideId ??= firstValue['scheduledRideId'] as String?;
            } else if (firstValue is String) {
              scheduledRideId = firstValue;
            }
          }

          // Set rideId if found
          if (scheduledRideId != null && scheduledRideId.isNotEmpty) {
            currentRideId.value = scheduledRideId;
            print('SAHAr: Scheduled ride ID: $scheduledRideId');
          }

          // Save held payment info to backend for scheduled rides
          if (heldPaymentIntentId.value.isNotEmpty && 
              heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
            await _saveHeldPaymentToBackend();
          }

          // Show success toast message
          Get.snackbar(
            'Scheduled Ride Received Successfully!',
            'Your ride has been scheduled for ${DateFormat('MMM dd, yyyy hh:mm a').format(getScheduledDateTime()!)}',
            duration: const Duration(seconds: 5),
            backgroundColor: MColor.primaryNavy.withValues(alpha:0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
          );
          
          // Clear everything after successful scheduled ride
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
          rating.value = (rideData['driverAverageRating'] ?? 0.0).toDouble();

          // IMPORTANT: Extract driver's Stripe Connected Account ID
          driverStripeAccountId.value = rideData['driverStripeAccount'] ?? rideData['driverStripeAccount'] ?? '';

          print(' SAHArSAHAr ✅ Driver found!');
          print(' SAHArSAHAr Driver ID: ${driverId.value}');
          print(' SAHArSAHAr Driver Name: ${driverName.value}');
          print(' SAHArSAHAr Driver Stripe Account: ${driverStripeAccountId.value}');

          if (driverStripeAccountId.value.isEmpty) {
            print(' SAHArSAHAr ⚠️ WARNING: Driver does not have Stripe account!');
          }

          // Set up SignalR subscription for ride updates
          if (currentRideId.value.isNotEmpty) {
            signalRService.subscribeToRide(currentRideId.value);
          }

          // Save held payment info to backend now that we have rideId and driverId
          if (heldPaymentIntentId.value.isNotEmpty && 
              heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
            await _saveHeldPaymentToBackend();
          }

          Get.snackbar(
              'Driver Assigned!',
              'Driver ${driverName.value} has been assigned to your ride.'
          );
        } else if (rideData is String && rideData.contains('No live drivers available')) {
          rideStatus.value = RideStatus.noDriver;
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
  }

  Future<void> _showPaymentDialog(Map<String, dynamic> tripData) async {
    print(' SAHArSAHAr Showing payment dialog with data: $tripData');
    prevRideId.value = tripData['rideId'];
    String rideId = tripData['rideId'] ?? currentRideId.value;
    double finalFare = (tripData['finalFare'] ?? tripData['totalFare'] ?? estimatedPrice.value).toDouble();
    double distance = (tripData['distance'] ?? 0.0).toDouble();
    String rideStartTime = tripData['rideStartTime'] ?? '';
    String rideEndTime = tripData['rideEndTime'] ?? '';
    String duration = tripData['duration'] ?? tripData['totalWaitingTime'] ?? '';

    // Store actual fare before balance deduction
    actualFareBeforeBalance.value = finalFare;

    // Store the original held payment amount before updating
    double originalHeldAmount = estimatedPrice.value;

    // Update estimated price with actual final fare from API
    estimatedPrice.value = finalFare;

    // Calculate the difference (held amount - final fare)
    double heldPaymentDifference = originalHeldAmount - finalFare;

    print(' SAHArSAHAr 💰 Actual Fare: \$${finalFare.toStringAsFixed(2)}');
    print(' SAHArSAHAr 💳 Held Payment Amount: \$${heldPaymentDifference.toStringAsFixed(2)}');

    // Store payment dialog data for potential re-opening
    _paymentDialogData = {
      'rideId': rideId,
      'finalFare': finalFare,
      'distance': distance,
      'duration': duration,
      'rideStartTime': rideStartTime,
      'rideEndTime': rideEndTime,
      'originalHeldAmount': originalHeldAmount,
      'heldPaymentDifference': heldPaymentDifference,
    };

    _showPaymentPopup(
      rideId: rideId,
      finalFare: finalFare,
      distance: distance,
      duration: duration,
      rideStartTime: rideStartTime,
      rideEndTime: rideEndTime,
      originalHeldAmount: originalHeldAmount,
      heldPaymentDifference: heldPaymentDifference,
    );
  }

  Future<double> calculatePrice(double finalFare) async {

    print(' SAHArSAHAr 📊 Final Fare: \$${finalFare.toStringAsFixed(2)}');

    return finalFare > 0 ? finalFare : 0;
  }


  // Enhanced payment methods with better UI
  void _showPaymentPopup({
    required String rideId,
    required double finalFare,
    required double distance,
    required String duration,
    required String rideStartTime,
    required String rideEndTime,
    required double originalHeldAmount,
    required double heldPaymentDifference,
  }) {
    // Reset tip amount when payment dialog opens
    selectedTipAmount.value = 0.0;
    
    // Reset ride duration display
    rideDurationDisplay.value = 'Calculating...';
    Timer? durationTimer;

    // Function to calculate and format duration
    String calculateRideDuration() {
      try {
        if (rideStartTime.isEmpty || rideEndTime.isEmpty) {
          return 'N/A';
        }

        // Try to parse the datetime strings
        DateTime startTime;
        DateTime endTime;

        // Try ISO 8601 format first
        try {
          startTime = DateTime.parse(rideStartTime);
          endTime = DateTime.parse(rideEndTime);
        } catch (e) {
          // Try other common formats
          try {
            startTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(rideStartTime);
            endTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(rideEndTime);
          } catch (e2) {
            try {
              startTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(rideStartTime);
              endTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(rideEndTime);
            } catch (e3) {
              return 'N/A';
            }
          }
        }

        Duration difference = endTime.difference(startTime);
        int hours = difference.inHours;
        int minutes = difference.inMinutes.remainder(60);
        int seconds = difference.inSeconds.remainder(60);

        if (hours > 0) {
          return '${hours}h ${minutes}m ${seconds}s';
        } else if (minutes > 0) {
          return '${minutes}m ${seconds}s';
        } else {
          return '${seconds}s';
        }
      } catch (e) {
        print('Error calculating ride duration: $e');
        return 'N/A';
      }
    }

    // Initialize duration display
    rideDurationDisplay.value = calculateRideDuration();

    // Update duration every second if needed (for live updates)
    durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      rideDurationDisplay.value = calculateRideDuration();
    });

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
                    Obx(() => _buildSummaryRow('Duration', rideDurationDisplay.value)),
                    SizedBox(height: 8),
                    _buildSummaryRow('Already Paid', originalHeldAmount > 0 ? '\$${originalHeldAmount.toStringAsFixed(2)}' : '\$0.00'),
                    SizedBox(height: 8),
                    _buildSummaryRow('Fare', finalFare <= 0 ? '\$0.00' : '\$${finalFare.toStringAsFixed(2)}'),
                    Obx(() => selectedTipAmount.value > 0 
                      ? Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: _buildSummaryRow('Tip', '\$${selectedTipAmount.value.toStringAsFixed(2)}'),
                        )
                      : SizedBox.shrink()),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 8),
                    Obx(() {
                      double totalAmount = finalFare + selectedTipAmount.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                              totalAmount <= 0
                                  ? "\$0.00"
                                  : "\$${totalAmount.toStringAsFixed(2)}",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MColor.primaryNavy)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          // Payment buttons
          Obx(() => Column(
            children: [
              if (!isLoading.value) ...[
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
                      _showTipDialog(finalFare <= 0 ? 0 : finalFare, originalHeldAmount);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8),
                        Obx(() => Text(
                          selectedTipAmount.value > 0 ? 'Change Tip' : 'Add Tip',
                          style: TextStyle(color: MColor.primaryNavy, fontWeight: FontWeight.w500)
                        )),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColor.primaryNavy,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      // Don't close dialog - let payment completion handle it
                      await _completePayment(finalFare, tipAmount: selectedTipAmount.value);
                    },
                    child: Obx(() {
                      double totalWithTip = finalFare + selectedTipAmount.value;
                      double amountToPay = totalWithTip - originalHeldAmount;
                      
                      String buttonText;
                      if (amountToPay <= 0) {
                        buttonText = amountToPay == 0 ? "Complete Ride" : "Complete Ride";
                      } else {
                        buttonText = "Pay \$${amountToPay.toStringAsFixed(2)}";
                      }
                      
                      return Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ] else ...[
                // Show loading indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(MColor.primaryNavy),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing payment...',
                        style: TextStyle(
                          fontSize: 16,
                          color: MColor.primaryNavy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait, do not close this window',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          )),
        ],
      ),
      barrierDismissible: false,
    ).then((_) {
      // Clean up timer when dialog is closed
      durationTimer?.cancel();
    });
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

  void _showTipDialog(double finalFare, double originalHeldAmount) {
    // Ensure finalFare is never negative
    if (finalFare < 0) {
      finalFare = 0.0;
    }

    // Initialize with current selected tip if any
    RxDouble selectedTip = selectedTipAmount.value.obs;
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
                  color: MColor.primaryNavy.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Fare: \$${finalFare.toStringAsFixed(2)}'),
                    if (selectedTip.value > 0) ...[
                      Text('Tip: \$${selectedTip.value.toStringAsFixed(2)}',
                          style: TextStyle(color: MColor.primaryNavy)),
                    ],
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
                      selectedColor: MColor.primaryNavy.withValues(alpha:0.3),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text('Cancel', style: TextStyle(color: MColor.primaryNavy)),
              ),
              Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColor.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Store selected tip and return to payment dialog
                  selectedTipAmount.value = selectedTip.value;
                  Get.back();
                  
                  // Re-open payment dialog with tip included if we have stored data
                  if (_paymentDialogData != null) {
                    _showPaymentPopup(
                      rideId: _paymentDialogData!['rideId'],
                      finalFare: _paymentDialogData!['finalFare'],
                      distance: _paymentDialogData!['distance'],
                      duration: _paymentDialogData!['duration'],
                      rideStartTime: _paymentDialogData!['rideStartTime'],
                      rideEndTime: _paymentDialogData!['rideEndTime'],
                      originalHeldAmount: _paymentDialogData!['originalHeldAmount'],
                      heldPaymentDifference: _paymentDialogData!['heldPaymentDifference'],
                    );
                  }
                },
                child: Text(
                  selectedTip.value > 0 ? 'Confirm Tip' : 'No Tip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
      barrierDismissible: true,
    );
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
        "rideId": prevRideId.value,
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
          backgroundColor: MColor.primaryNavy.withValues(alpha:0.8),
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

  // Show review/feedback dialog
  void _showReviewDialog() {
    RxInt selectedRating = 0.obs;
    TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.star, color: MColor.trackingOrange, size: 28),
            SizedBox(width: 8),
            Text('Rate Your Rider',
                style: TextStyle(
                  color: MColor.primaryNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )
            ),
          ],
        ),
        content: Container(
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your ride with ${driverName.value}?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Star rating
              Obx(() => FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating.value ? Icons.star : Icons.star_border,
                        size: 24,
                        color: MColor.trackingOrange,
                      ),
                      onPressed: () {
                        selectedRating.value = index + 1;
                      },
                    );
                  }),
                ),
              )),

              SizedBox(height: 20),

              // Comment field
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  filled: true,
                  fillColor: MColor.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MColor.lightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MColor.primaryNavy, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              clearBooking();
            },
            child: Text('Skip', style: TextStyle(color: MColor.mediumGrey)),
          ),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MColor.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: selectedRating.value > 0 ? () async {
              Get.back();
              await _submitFeedback(
                  selectedRating.value,
                  commentController.text.trim()
              );
              clearBooking();
            } : null,
            child: Text(
              'Submit Review',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
              ),
            ),
          )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Submit feedback to API
  Future<void> _submitFeedback(int rating, String comments) async {
    print(' SAHArSAHAr 🟡 _submitFeedback() called');
    print(' SAHArSAHAr ⭐ Rating: $rating');
    print(' SAHArSAHAr 💬 Comments: $comments');

    try {
      isLoading.value = true;
      print(' SAHArSAHAr ⏳ isLoading set to true');

      var userId = await SharedPrefsService.getUserId() ?? AppConstants.defaultUserId;
      var userName = await SharedPrefsService.getUserFullName() ?? AppConstants.defaultUserName;

      Map<String, dynamic> feedbackData = {
        "rideId": prevRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "rating": rating,
        "comments": comments.isEmpty ? null : comments,
        "createdAt": DateTime.now().toIso8601String(),
        "feedbackFrom": "User",
        "driverName": driverName.value,
        "userName": userName,
      };

      print(' SAHArSAHAr 📦 Feedback Payload: $feedbackData');

      Response response = await _apiProvider.postData(ApiEndpoints.submitFeedback, feedbackData);
      print(' SAHArSAHAr 📥 API Response: ${response.body}');

      if (response.isOk) {
        print(' SAHArSAHAr ✅ Feedback submitted successfully');
        Get.snackbar(
          'Thank You!',
          'Your feedback has been submitted successfully!',
          duration: Duration(seconds: 3),
          backgroundColor: MColor.primaryNavy.withValues(alpha:0.8),
          colorText: Colors.white,
        );
      } else {
        print(' SAHArSAHAr ❌ Feedback submission failed: ${response.statusText}');
        Get.snackbar('Error', 'Failed to submit feedback: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr 🔥 Exception during feedback submission: $e');
      Get.snackbar('Error', 'Failed to submit feedback: $e');
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

    // Reset fare estimation tracking when pickup location changes
    _lastFareEstimateKey = '';
    _hasShownServiceUnavailable = false;
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

    // Reset destination tracking
    isTrackingDestination.value = false;
    distanceToDestination.value = 0.0;
  }

  void clearBooking() {
    _mapService.clearMap();
    isRideBooked.value = false;
    resetForm();
    _locationService.getCurrentLocation();

    // Reset notification flags for next ride
    hasShownApproachingNotification.value = false;
    hasShownArrivedNotification.value = false;

    // Reset destination tracking
    isTrackingDestination.value = false;
    distanceToDestination.value = 0.0;
  }

  /// STEP 1: Hold payment first, then start the ride (book/find driver or schedule)
  Future<void> startRideWithPayment() async {
    print('SAHAr: startRideWithPayment() called');

    // Validations
    if (! isRideBooked. value) {
      print('SAHAr: Ride not booked yet');
      Get.snackbar('Error', 'Please book a ride first');
      return;
    }

    if (pickupLocation.value == null || dropoffLocation.value == null) {
      print('SAHAr: Missing pickup or dropoff location');
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return;
    }

    if (isScheduled.value) {
      if (scheduledDate.value == null || scheduledTime.value == null) {
        Get.snackbar('Incomplete Schedule', 'Please set both date and time');
        return;
      }

      DateTime scheduledDateTime = getScheduledDateTime()! ;
      if (scheduledDateTime.isBefore(DateTime.now())) {
        Get.snackbar('Invalid Schedule', 'Scheduled time cannot be in the past');
        return;
      }
    }

    try {
      isLoading.value = true;

      // Use the estimated fare for payment hold
      double amountToHold = (estimatedFare.value > 0)
          ? estimatedFare. value
          : estimatedPrice.value;

      print('SAHAr: Holding payment amount: $amountToHold');

      // Store the amount being held
      _heldAmount = amountToHold;

      // HOLD the payment (not capture yet)
      bool paymentHeld = await _holdStripePayment(amountToHold);

      if (!paymentHeld) {
        print('SAHAr: Payment hold failed or cancelled');
        return; // Error already shown in _holdStripePayment
      }

      print('SAHAr: ✅ Payment held successfully! ');
      print('SAHAr: Payment Intent ID: ${heldPaymentIntentId.value}');

      // Now proceed to start the ride (find driver)
      // Note: We'll save held payment to backend AFTER ride is created (in _handleRideResponse)
      await startRide(heldPaymentIntentId.value); // Pass payment intent as token

    } catch (e) {
      print('SAHAr: Exception in startRideWithPayment:  $e');
      Get.snackbar('Error', 'Failed to process payment/start ride: $e');
    } finally {
      isLoading.value = false;
      print('SAHAr: startRideWithPayment completed');
    }
  }

  /// HOLD payment (authorize without capturing)
  Future<bool> _holdStripePayment(double amount) async {
    try {
      print('SAHAr: Starting _holdStripePayment with amount: $amount');

      if (amount <= 0) {
        print('SAHAr:  Amount is 0 or negative, no payment hold needed');
        heldPaymentIntentId.value = 'NO_PAYMENT_REQUIRED';
        return true;
      }

      int amountInCents = (amount * 100).round();
      print('SAHAr:  Converted amount to cents: $amountInCents');

      // Create payment intent with HOLD (manual capture)
      Map<String, dynamic>? paymentIntent =
      await PaymentService.createPaymentIntentWithHold(
        amount: amountInCents. toString(),
        currency: 'cad',
        description: 'Ride payment - On Hold',
      );

      if (paymentIntent == null) {
        print('SAHAr:  Failed to create payment intent');
        Get.snackbar('Error', 'Failed to create payment hold');
        return false;
      }

      print('SAHAr: Received paymentIntent: $paymentIntent');
      String paymentIntentId = paymentIntent['id'] ?? '';
      print('SAHAr: Payment Intent ID: $paymentIntentId');

      // Show Stripe payment sheet to authorize payment
      var userName = await SharedPrefsService.getUserFullName() ??
          AppConstants.defaultUserName;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: userName,
        ),
      );

      print('SAHAr: Payment sheet initialized');

      await Stripe.instance.presentPaymentSheet();
      print('SAHAr: Payment sheet presented successfully');

      // Save payment intent ID
      heldPaymentIntentId.value = paymentIntentId;

      print('SAHAr: ✅ Payment authorized and held! ');
      return true;

    } on StripeException catch (e) {
      print('SAHAr:  StripeException: ${e. error.localizedMessage}');
      Get.snackbar('Payment Cancelled', 'Payment authorization was cancelled');
      return false;
    } catch (e) {
      print('SAHAr: Error in _holdStripePayment:  $e');
      Get.snackbar('Payment Error', 'Failed to authorize payment: $e');
      return false;
    }
  }

  /// Save held payment info to backend (non-blocking)
  /// This should be called AFTER ride is created (when rideId and driverId are available)
  Future<void> _saveHeldPaymentToBackend() async {
    try {
      var userId = await SharedPrefsService.getUserId() ??
          AppConstants.defaultUserId;

      // Ensure we have required fields
      String rideId = currentRideId.value.isNotEmpty ? currentRideId.value : prevRideId.value;
      if (rideId.isEmpty) {
        print('SAHAr: ⚠️ Cannot save held payment - rideId is empty');
        return;
      }

      // Don't save if no payment was held
      if (_heldAmount <= 0) {
        print('SAHAr: ⚠️ Cannot save held payment - held amount is 0 or negative');
        return;
      }

      // Use default driverId if not available (for scheduled rides, driver might not be assigned yet)
      String driverIdValue = driverId.value.isNotEmpty 
          ? driverId.value 
          : "00000000-0000-0000-0000-000000000000"; // Default GUID for pending assignment

      Map<String, dynamic> holdData = {
        "rideId": rideId,
        "userId": userId,
        "paymentIntentId": heldPaymentIntentId.value,
        "heldAmount": _heldAmount, // Use the actual amount that was held
        "driverId": driverIdValue,
        "paymentMethod": "Credit Card", // Stripe payments are credit card
      };

      print('SAHAr: 💾 Saving held payment to backend: $holdData');

      Response response = await _apiProvider.postData(
        ApiEndpoints.saveHeldPayment, // Backend endpoint
        holdData,
      );

      if (response.isOk) {
        print('SAHAr: ✅ Held payment saved successfully');
      } else {
        // Log but don't fail the ride - backend endpoint might not exist yet
        print('SAHAr: ⚠️ Failed to save held payment: ${response.statusText} (Status: ${response.statusCode})');
        print('SAHAr: ⚠️ Response body: ${response.body}');
        print('SAHAr: ⚠️ This is non-critical - ride can still proceed');

        if (response.statusCode == 404) {
          print('SAHAr: ⚠️ Backend endpoint ${ApiEndpoints.saveHeldPayment} not found. Please implement this endpoint.');
        }
      }
    } catch (e) {
      // Log but don't fail the ride
      print('SAHAr: ⚠️ Error saving held payment: $e');
      print('SAHAr: ⚠️ This is non-critical - ride can still proceed');
    }
  }

  /// STEP 2: When driver is found, save driver's Stripe ID
  void onDriverFound(Map<String, dynamic> driverData) {
    driverId.value = driverData['driverId'] ?? '';
    driverName.value = driverData['driverName'] ?? '';

    // IMPORTANT: Get driver's Stripe Connected Account ID
    driverStripeAccountId.value = driverData['driverStripeId'] ?? '';

    print('SAHAr: Driver found! ');
    print('SAHAr: Driver ID: ${driverId.value}');
    print('SAHAr: Driver Name: ${driverName.value}');
    print('SAHAr: Driver Stripe Account:  ${driverStripeAccountId. value}');

    if (driverStripeAccountId. value.isEmpty) {
      print('SAHAr: ⚠️ WARNING: Driver does not have Stripe account! ');
    }
  }

  /// STEP 3: Complete payment when ride ends (capture + transfer)
  Future<void> _completePayment(double fareAfterBalance, {double tipAmount = 0.0}) async {
    double totalAmountWithTip = fareAfterBalance + tipAmount;

    try {
      print('SAHAr: Starting _completePayment');
      print('SAHAr: 💰 Actual Fare (before balance): \$${actualFareBeforeBalance.value.toStringAsFixed(2)}');
      print('SAHAr: 💰 Fare after balance deduction: \$${fareAfterBalance.toStringAsFixed(2)}');
      print('SAHAr: 💰 Tip amount: \$${tipAmount.toStringAsFixed(2)}');
      print('SAHAr: 💰 Total to charge (fare + tip after balance): \$${totalAmountWithTip.toStringAsFixed(2)}');
      print('SAHAr: 💳 Held payment amount: \$${estimatedPrice.value.toStringAsFixed(2)}');
      isLoading.value = true;

      var userId = await SharedPrefsService.getUserId() ??
          AppConstants.defaultUserId;

      print('SAHAr: 📱 Retrieved user ID: $userId');

      double balanceUsed = actualFareBeforeBalance.value - fareAfterBalance;
      print('SAHAr: 💵 Balance Used: \$${balanceUsed.toStringAsFixed(2)}');

      // If balance covers the full fare (no card charge needed)
      if (totalAmountWithTip <= 0) {
        print('SAHAr: 💰 User balance covers the full fare - no card charge needed');

        // Cancel held payment if it exists
        if (heldPaymentIntentId.value.isNotEmpty &&
            heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
          print('SAHAr: Canceling held payment: ${heldPaymentIntentId.value}');
          await PaymentService.cancelHeldPayment(heldPaymentIntentId.value);
        }

        // Record as balance-paid ride (with actual fare amount)
        await _recordNoPaymentRide(fareAmount: actualFareBeforeBalance.value);

        // Close the payment dialog
        Get.back();

        _showRideCompletedMessage(0, 0, paidFromBalance: true);
        _showReviewDialog();
        return;
      }

      // Check if we have held payment for card charge
      if (heldPaymentIntentId.value.isEmpty ||
          heldPaymentIntentId.value == 'NO_PAYMENT_REQUIRED') {
        Get.snackbar('Error', 'No held payment found');
        print('SAHAr: ❌ No held payment intent available');
        return;
      }

      // Check driver's Stripe account
      if (driverStripeAccountId.value.isEmpty) {
        Get.snackbar('Error', 'Driver payment details not available');
        print('SAHAr: ⚠️ Driver Stripe account missing!');
        return;
      }

      // CRITICAL: Calculate the actual amount to capture
      // The held amount might be higher than what we need to charge
      int heldAmountCents = (_heldAmount * 100).round();
      int fareOnlyCents = (fareAfterBalance * 100).round();
      int tipAmountCents = (tipAmount * 100).round();
      int actualChargeWithTipCents = fareOnlyCents + tipAmountCents;

      print('SAHAr: 💳 Held Amount: ${heldAmountCents} cents (\$${(heldAmountCents/100).toStringAsFixed(2)})');
      print('SAHAr: 💳 Fare to Capture: ${fareOnlyCents} cents (\$${(fareOnlyCents/100).toStringAsFixed(2)})');
      print('SAHAr: 💳 Tip Amount: ${tipAmountCents} cents (\$${(tipAmountCents/100).toStringAsFixed(2)})');
      print('SAHAr: 💳 Total Needed: ${actualChargeWithTipCents} cents (\$${(actualChargeWithTipCents/100).toStringAsFixed(2)})');

      Map<String, String>? additionalPaymentInfo;
      int amountToCaptureFromHeld;
      int tipInHeldPayment;
      int additionalAmountNeeded = 0;

      // Check if total exceeds held amount
      if (actualChargeWithTipCents > heldAmountCents) {
        print('SAHAr: ⚠️ Total needed exceeds held amount - creating additional payment intent');
        additionalAmountNeeded = actualChargeWithTipCents - heldAmountCents;
        
        // Create additional payment intent for the excess amount
        additionalPaymentInfo = await _createAdditionalPaymentIntent(additionalAmountNeeded);
        
        if (additionalPaymentInfo == null || additionalPaymentInfo['chargeId'] == null || additionalPaymentInfo['chargeId']!.isEmpty) {
          print('SAHAr: ❌ Failed to create additional payment intent');
          Get.snackbar('Payment Error', 'Failed to process additional payment for tip. Please try again.');
          return;
        }
        
        // Capture full held amount (fare + any tip that fits)
        amountToCaptureFromHeld = heldAmountCents;
        tipInHeldPayment = heldAmountCents - fareOnlyCents; // Tip that fits in held amount
        if (tipInHeldPayment < 0) tipInHeldPayment = 0;
        
        print('SAHAr: 💡 Capturing held payment: \$${(amountToCaptureFromHeld/100).toStringAsFixed(2)}');
        print('SAHAr: 💡 Additional payment created: ${additionalPaymentInfo['paymentIntentId']} for \$${(additionalAmountNeeded/100).toStringAsFixed(2)}');
      } else {
        // Normal case: everything fits in held amount
        amountToCaptureFromHeld = actualChargeWithTipCents;
        tipInHeldPayment = tipAmountCents;
        print('SAHAr: ✅ Total charge fits within held amount');
      }

      // CAPTURE held payment and TRANSFER to driver
      final result = await PaymentService.captureAndTransferPayment(
        paymentIntentId: heldPaymentIntentId.value,
        driverStripeAccountId: driverStripeAccountId.value,
        totalAmountCents: amountToCaptureFromHeld,
        tipAmountCents: tipInHeldPayment,
      );

      if (result == null || result['success'] != true) {
        print('SAHAr: ❌ Failed to capture held payment');
        Get.snackbar('Payment Failed', 'Failed to complete payment. Please try again or contact support.');
        return;
      }

      // If we have additional payment, transfer it to driver too
      Map<String, dynamic>? additionalResult;
      if (additionalPaymentInfo != null && additionalPaymentInfo['chargeId'] != null && additionalAmountNeeded > 0) {
        print('SAHAr: 💳 Processing additional payment for tip');
        
        String additionalChargeId = additionalPaymentInfo['chargeId']!;
        
        // Transfer additional tip amount to driver (100% of tip goes to driver)
        additionalResult = await PaymentService.transferAdditionalAmount(
          chargeId: additionalChargeId,
          driverStripeAccountId: driverStripeAccountId.value,
          amountCents: additionalAmountNeeded,
          tipAmountCents: additionalAmountNeeded, // Full additional amount is tip
        );
        
        if (additionalResult == null || additionalResult['success'] != true) {
          print('SAHAr: ⚠️ Warning: Additional payment captured but transfer failed');
        }
      }

      print('SAHAr: ✅ Payment completed successfully!');

      // Calculate total tip processed (from held + additional if any)
      double totalTipProcessed = (tipInHeldPayment / 100.0);
      if (additionalResult != null && additionalResult['success'] == true) {
        totalTipProcessed += (additionalAmountNeeded / 100.0);
      }

      // Save transaction to backend
      await _saveCompletedTransaction(result, userId, totalTipProcessed, balanceUsed: balanceUsed);

      // Call tip API AFTER successful payment (only if tip > 0)
      if (tipAmount > 0) {
        print('SAHAr: 📤 Submitting tip to API after successful payment');
        await _submitTip(tipAmount, fareAfterBalance, totalAmountWithTip);
      }

      // Close the payment dialog now that payment is successful
      Get.back();

      // Show success message
      double driverAmount = result['driver_amount'] / 100;
      double platformFee = result['platform_fee'] / 100;
      
      // Add additional driver amount if additional payment was processed
      if (additionalResult != null && additionalResult['success'] == true) {
        driverAmount += (additionalAmountNeeded / 100.0); // Full tip goes to driver
      }

      _showRideCompletedMessage(driverAmount, platformFee, balanceUsed: balanceUsed);

      // Show review dialog
      _showReviewDialog();

      // Clear payment data
      _clearPaymentData();

    } catch (e) {
      print('SAHAr: ❌ Error in _completePayment: $e');
      Get.snackbar('Payment Error', 'Failed to process payment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Save completed transaction to backend
  Future<void> _saveCompletedTransaction(
      Map<String, dynamic> result,
      String userId,
      double tipAmount,
      {double balanceUsed = 0.0}
      ) async {
    try {
      Map<String, dynamic> paymentData = {
        "rideId": prevRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "paymentIntentId": result['payment_intent_id'],
        "transferId": result['transfer_id'],
        "totalAmount": result['total_amount'] / 100, // Convert to dollars
        "rideAmount": actualFareBeforeBalance.value, // Actual fare before balance
        "balanceUsed": balanceUsed, // Amount paid from balance
        "cardCharged": result['total_amount'] / 100, // Amount charged to card
        "tipAmount": tipAmount,
        "driverAmount": result['driver_amount'] / 100,
        "platformFee": result['platform_fee'] / 100,
        "status": "completed",
        "completedAt": DateTime.now().toIso8601String(),
      };

      print('SAHAr: Saving completed transaction: $paymentData');

      Response response = await _apiProvider.postData(
        ApiEndpoints.completeTransaction, // Backend endpoint
        paymentData,
      );

      if (response.isOk) {
        print('SAHAr: ✅ Transaction saved successfully');
      } else {
        print('SAHAr: ⚠️ Failed to save transaction: ${response.statusText}');
      }
    } catch (e) {
      print('SAHAr: ❌ Error saving transaction: $e');
    }
  }

  /// Record ride with no payment (for free rides or balance-paid rides)
  Future<void> _recordNoPaymentRide({double fareAmount = 0.0}) async {
    try {
      var userId = await SharedPrefsService. getUserId() ??
          AppConstants.defaultUserId;

      Map<String, dynamic> data = {
        "rideId": prevRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "amount": fareAmount, // Record actual fare (paid from balance)
        "status": fareAmount > 0 ? "completed_balance_paid" : "completed_no_payment",
        "completedAt": DateTime.now().toIso8601String(),
      };

      await _apiProvider.postData(ApiEndpoints.completeTransaction, data);
      print('SAHAr: ${fareAmount > 0 ? "Balance-paid" : "No-payment"} ride recorded (Amount: \$${fareAmount.toStringAsFixed(2)})');
    } catch (e) {
      print('SAHAr: Error recording no-payment ride:  $e');
    }
  }

  /// Show ride completed message
  void _showRideCompletedMessage(double driverAmount, double platformFee, {bool paidFromBalance = false, double balanceUsed = 0.0}) {
    String message;

    if (driverAmount == 0 && platformFee == 0) {
      if (paidFromBalance && actualFareBeforeBalance.value > 0) {
        message = "Ride completed successfully!\n"
            "Fare of \$${actualFareBeforeBalance.value.toStringAsFixed(2)} paid from your balance.";
      } else {
        message = "Ride completed successfully!\nNo payment required.";
      }
    } else {
      double cardCharged = driverAmount + platformFee;
      message = "Payment completed successfully!\n"
          "Total Fare: \$${actualFareBeforeBalance.value.toStringAsFixed(2)}\n";

      if (balanceUsed > 0) {
        message += "Balance Used: \$${balanceUsed.toStringAsFixed(2)}\n";
      }

      message += "Card Charged: \$${cardCharged.toStringAsFixed(2)}\n"
          "Driver received: \$${driverAmount.toStringAsFixed(2)}\n"
          "Service fee: \$${platformFee.toStringAsFixed(2)}";
    }

    Get.snackbar(
      driverAmount == 0 ? 'Ride Completed!' : 'Payment Successful!',
      message,
      backgroundColor: MColor.primaryNavy.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
    );
  }

  /// Cancel held payment (if ride is cancelled)
  Future<void> cancelRideAndRefund() async {
    try {
      if (heldPaymentIntentId.value.isNotEmpty &&
          heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {

        print('SAHAr:  Cancelling held payment...');

        bool cancelled = await PaymentService.cancelHeldPayment(
            heldPaymentIntentId.value
        );

        if (cancelled) {
          print('SAHAr: ✅ Payment hold cancelled successfully');

          // Update backend
          await _updateCancelledRideInBackend();

          Get.snackbar(
            'Ride Cancelled',
            'Payment hold has been released. No charges applied.',
            backgroundColor: Colors.orange. withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        } else {
          print('SAHAr: ❌ Failed to cancel payment hold');
        }

        _clearPaymentData();
      }
    } catch (e) {
      print('SAHAr: Error cancelling ride: $e');
    }
  }

  /// Cancel ride - releases Stripe payment hold and clears everything back to starting point
  Future<void> cancelRide() async {
    try {
      isLoading.value = true;

      print('SAHAr: Cancelling ride - releasing payment hold and clearing booking');

      // Show loading dialog with animation
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false, // Prevent closing during cancellation
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, fadeValue, child) {
                return Opacity(
                  opacity: fadeValue,
                  child: Transform.scale(
                    scale: 0.9 + (fadeValue * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated loading indicator
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (value * 0.2),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withValues(alpha: 0.1),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                      Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Animated text
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - value)),
                                  child: Text(
                                    'Cancelling ride...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Small delay for animation to show
      await Future.delayed(const Duration(milliseconds: 500));

      // Release Stripe payment hold if payment was held
      if (heldPaymentIntentId.value.isNotEmpty && 
          heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
        print('SAHAr: Releasing Stripe payment hold...');
        await PaymentService.cancelHeldPayment(heldPaymentIntentId.value);
        print('SAHAr: ✅ Payment hold released');
      }

      // Clear payment data
      _clearPaymentData();

      // Clear everything back to starting point
      clearBooking();

      // Close loading dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Show success animation
      await Future.delayed(const Duration(milliseconds: 200));
      
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ride Cancelled',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Payment hold released',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        barrierDismissible: true,
      );

      // Auto-close success dialog after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (Get.isDialogOpen == true) {
        Get.back();
      }

    } catch (e) {
      print('SAHAr: Error cancelling ride: $e');
      
      // Close loading dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Show error with animation
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.9 + (value * 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error cancelling ride: $e',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        barrierDismissible: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update cancelled ride in backend
  Future<void> _updateCancelledRideInBackend() async {
    try {
      await _apiProvider.postData(
        ApiEndpoints.cancelRide,
        {
          "rideId": prevRideId. value,
          "paymentIntentId": heldPaymentIntentId.value,
          "status": "cancelled",
          "cancelledAt": DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('SAHAr: Error updating cancelled ride: $e');
    }
  }

  /// Clear payment data
  void _clearPaymentData() {
    heldPaymentIntentId.value = '';
    driverStripeAccountId.value = '';
    _heldAmount = 0.0;
    selectedTipAmount.value = 0.0;
    _paymentDialogData = null;
    print('SAHAr: Payment data cleared');
  }

  /// Create additional payment intent for excess tip amount
  /// Returns map with 'paymentIntentId' and 'chargeId'
  Future<Map<String, String>?> _createAdditionalPaymentIntent(int amountCents) async {
    try {
      print('SAHAr: Creating additional payment intent for ${amountCents} cents');
      
      var userName = await SharedPrefsService.getUserFullName() ?? AppConstants.defaultUserName;
      
      // Create payment intent with automatic capture for additional amount
      Map<String, dynamic>? paymentIntent = await PaymentService.createPaymentIntentWithImmediateCapture(
        amount: amountCents.toString(),
        currency: 'cad',
        description: 'Additional tip payment',
      );
      
      if (paymentIntent == null) {
        print('SAHAr: ❌ Failed to create additional payment intent');
        return null;
      }
      
      String paymentIntentId = paymentIntent['id'];
      
      // Show Stripe payment sheet to authorize and capture additional payment
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: userName,
        ),
      );
      
      await Stripe.instance.presentPaymentSheet();
      print('SAHAr: ✅ Additional payment captured');
      
      // Retrieve payment intent to get charge ID after capture
      String? chargeId = await _getChargeIdFromPaymentIntent(paymentIntentId);
      
      if (chargeId == null) {
        print('SAHAr: ⚠️ Warning: Could not get charge ID from additional payment intent');
        // Still return payment intent ID, we can try to get charge ID later
      }
      
      return {
        'paymentIntentId': paymentIntentId,
        'chargeId': chargeId ?? '',
      };
    } on StripeException catch (e) {
      print('SAHAr: ❌ StripeException in additional payment: ${e.error.localizedMessage}');
      Get.snackbar('Payment Cancelled', 'Additional tip payment was cancelled');
      return null;
    } catch (e) {
      print('SAHAr: ❌ Error creating additional payment intent: $e');
      Get.snackbar('Payment Error', 'Failed to process additional tip payment: $e');
      return null;
    }
  }

  /// Get charge ID from payment intent
  Future<String?> _getChargeIdFromPaymentIntent(String paymentIntentId) async {
    try {
      final retrievedPI = await PaymentService.retrievePaymentIntent(paymentIntentId);
      if (retrievedPI != null) {
        if (retrievedPI['latest_charge'] != null) {
          return retrievedPI['latest_charge'];
        } else if (retrievedPI['charges'] != null &&
                   retrievedPI['charges']['data'] != null &&
                   retrievedPI['charges']['data'].isNotEmpty) {
          return retrievedPI['charges']['data'][0]['id'];
        }
      }
      return null;
    } catch (e) {
      print('SAHAr: ❌ Error getting charge ID: $e');
      return null;
    }
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
