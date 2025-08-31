import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/core/google_places_service.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/models/ride_models.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/core/google_directions_service.dart';
import 'package:pick_u/taxi/ride_booking_page.dart';

class RideBookingController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final LocationService _locationService = Get.find<LocationService>();

  // Text Controllers
  final pickupController = TextEditingController();
  final dropoffController = TextEditingController();
  var stopControllers = <TextEditingController>[].obs;

  // Observable variables
  var isLoading = false.obs;
  var currentPosition = Rx<Position?>(null);
  var pickupLocation = Rx<LocationData?>(null);
  var dropoffLocation = Rx<LocationData?>(null);
  var additionalStops = <LocationData>[].obs;
  var searchSuggestions = <AutocompletePrediction>[].obs;
  var isSearching = false.obs;
  Timer? _searchTimer;
  var activeSearchField = ''.obs;
  var passengerCount = 1.obs;
  var rideType = 'standard'.obs;
  var fareEstimate = 0.0.obs;
  var isMultiStopRide = false.obs;

  // Map display variables
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isRideBooked = false.obs;

  // Route information
  var routeDistance = ''.obs;
  var routeDuration = ''.obs;
  var isLoadingRoute = false.obs;

  // Ride tracking
  var currentRideId = ''.obs;
  var rideStatus = 'pending'.obs;

  // Driver information
  var driverId = ''.obs;
  var driverName = ''.obs;
  var driverPhone = ''.obs;
  var estimatedPrice = 0.0.obs;
  var vehicle = ''.obs;
  var vehicleColor =''.obs;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  @override
  void onClose() {
    _searchTimer?.cancel();
    pickupController.dispose();
    dropoffController.dispose();
    for (var controller in stopControllers) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> getCurrentLocation() async {
    isLoading.value = true;
    try {
      bool hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        Get.snackbar('Permission Required', 'Location permission is required');
        isLoading.value = false;
        return;
      }

      Position? position = await _locationService.getCurrentPosition();
      if (position != null) {
        currentPosition.value = position;
        String address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        pickupLocation.value = LocationData(
          address: address,
          latitude: position.latitude,
          longitude: position.longitude,
          stopOrder: 0,
        );
        pickupController.text = address;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchLocation(String query, String fieldType) async {
    _searchTimer?.cancel();
    if (query.length < 2) {
      searchSuggestions.clear();
      return;
    }

    activeSearchField.value = fieldType;
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      await _performLocationSearch(query);
    });
  }

  Future<void> _performLocationSearch(String query) async {
    try {
      isSearching.value = true;

      // Get current location for location bias
      LatLng? currentLatLng;
      if (currentPosition.value != null) {
        currentLatLng = LatLng(
          currentPosition.value!.latitude,
          currentPosition.value!.longitude,
        );
      }

      // Get autocomplete suggestions from Google Places API
      List<AutocompletePrediction> predictions = await GooglePlacesService.getAutocompleteSuggestions(
        input: query,
        location: currentLatLng,
        radius: 50000, // 50km radius around current location
      );

      searchSuggestions.value = predictions;

    } catch (e) {
      print(' MRSAHAr Error searching locations: $e');
      Get.snackbar('Search Error', 'Failed to search locations. Please try again.');
      searchSuggestions.clear();
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectSuggestion(AutocompletePrediction prediction) async {
    try {
      isLoading.value = true;
      searchSuggestions.clear();

      // Get detailed place information
      PlaceDetails? placeDetails = await GooglePlacesService.getPlaceDetails(prediction.placeId);

      if (placeDetails == null) {
        Get.snackbar('Error', 'Failed to get location details');
        return;
      }

      if (activeSearchField.value == 'pickup') {
        pickupController.text = placeDetails.formattedAddress;
        pickupLocation.value = LocationData(
          address: placeDetails.formattedAddress,
          latitude: placeDetails.location.latitude,
          longitude: placeDetails.location.longitude,
          stopOrder: 0,
        );
      } else if (activeSearchField.value == 'dropoff') {
        dropoffController.text = placeDetails.formattedAddress;
        dropoffLocation.value = LocationData(
          address: placeDetails.formattedAddress,
          latitude: placeDetails.location.latitude,
          longitude: placeDetails.location.longitude,
          stopOrder: 1,
        );
      } else if (activeSearchField.value.startsWith('stop_')) {
        int stopIndex = int.parse(activeSearchField.value.split('_')[1]);
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

      activeSearchField.value = '';

    } catch (e) {
      print(' MRSAHAr Error selecting suggestion: $e');
      Get.snackbar('Error', 'Failed to select location');
    } finally {
      isLoading.value = false;
    }
  }

  void addStop() {
    final controller = TextEditingController();
    stopControllers.add(controller);

    additionalStops.add(LocationData(
      address: '',
      latitude: 0,
      longitude: 0,
      stopOrder: additionalStops.length + 2,
    ));
  }

  void removeStop(int index) {
    if (index < stopControllers.length) {
      stopControllers[index].dispose();
      stopControllers.removeAt(index);
      if (index < additionalStops.length) {
        additionalStops.removeAt(index);
      }
    }
  }

  void setRideType(String type) {
    rideType.value = type;
    if (type == 'Multi-Stop Ride') {
      isMultiStopRide.value = true;
    } else {
      isMultiStopRide.value = false;
    }
  }

  // FIXED: This method now properly sets isRideBooked = true
  Future<void> bookRide() async {
    if (pickupLocation.value == null || dropoffLocation.value == null) {
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return;
    }

    try {
      isLoading.value = true;

      // Create markers and polylines with real routes
      await _createMarkersAndPolylines();

      // Set ride as booked to show Edit and Start Ride buttons
      isRideBooked.value = true;
      rideStatus.value = 'booked';

      Get.snackbar(
        'Success',
        'Route calculated!\nDistance: ${routeDistance.value}\nDuration: ${routeDuration.value}',
        duration: const Duration(seconds: 3),
      );

      // Go back to HomeScreen to show the route with buttons
      Get.back();

    } catch (e) {
      Get.snackbar('Error', 'Booking failed: $e');
      isRideBooked.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED: This method now calls the correct API endpoint and handles different response states
  Future<void> startRide() async {
    print('MRSAHAr startRide() called');

    if (!isRideBooked.value) {
      print('MRSAHAr Ride not booked yet');
      Get.snackbar('Error', 'Please book a ride first');
      return;
    }

    if (pickupLocation.value == null || dropoffLocation.value == null) {
      print('MRSAHAr Missing pickup or dropoff location');
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return;
    }

    try {
      isLoading.value = true;
      print('MRSAHAr Preparing stops...');

      List<Map<String, dynamic>> allStops = [];

      // Pickup
      allStops.add({
        "stopOrder": 0,
        "location": pickupLocation.value!.address,
        "latitude": pickupLocation.value!.latitude,
        "longitude": pickupLocation.value!.longitude,
      });
      print('MRSAHAr Added pickup: ${pickupLocation.value!.address}');

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
          print('MRSAHAr Added stop ${i + 1}: ${stop.address}');
        }
      }

      // Dropoff
      allStops.add({
        "stopOrder": allStops.length,
        "location": dropoffLocation.value!.address,
        "latitude": dropoffLocation.value!.latitude,
        "longitude": dropoffLocation.value!.longitude,
      });
      print('MRSAHAr Added dropoff: ${dropoffLocation.value!.address}');

      Map<String, dynamic> requestData = {
        "userId": "44f9ebba-b24d-4df1-8a60-bd7035b6097d",
        "rideType": rideType.value,
        "isScheduled": false,
        "scheduledTime": DateTime.now().toIso8601String(),
        "passengerCount": passengerCount.value,
        "fareEstimate": fareEstimate.value,
        "stops": allStops,
      };

      print('MRSAHAr Request payload: $requestData');

      // Set status to waiting while API processes
      rideStatus.value = 'waiting';

      Response response = await _apiProvider.postData('/api/Ride/book', requestData);
      print('MRSAHAr API response: ${response.body}');

      if (response.isOk) {
        var responseBody = response.body;
        print('MRSAHAr Response body: $responseBody');

        // Check if response contains ride data
        if (responseBody is Map<String, dynamic>) {
          String rideIdKey = responseBody.keys.first;
          var rideData = responseBody[rideIdKey];

          if (rideData is Map<String, dynamic>) {
            // Driver found - extract driver information
            currentRideId.value = rideData['rideId'] ?? '';;
            driverId.value = rideData['driverId'] ?? '';
            driverName.value = rideData['driverName'] ?? '';
            driverPhone.value = rideData['driverPhone'] ?? '';
            vehicleColor.value = rideData['vehicle'] ?? '';
            vehicle.value = rideData['vehicleColor'] ?? '';
            estimatedPrice.value = (rideData['estimatedPrice'] ?? 0.0).toDouble();
            rideStatus.value = 'driver_assigned';

            Get.snackbar(
                'Driver Assigned!',
                'Driver ${driverName.value} has been assigned to your ride.'
            );
          } else if (rideData is String && rideData.contains('No live drivers available')) {
            // No drivers available
            rideStatus.value = 'no_driver';
            Get.snackbar(
              'No Drivers Available',
              'No live drivers available right now. Please try again later.',
              duration: const Duration(seconds: 4),
            );
          }
        }
      } else {
        rideStatus.value = 'error';
        Get.snackbar('Error', 'Failed to start ride: ${response.statusText}');
      }
    } catch (e) {
      print('MRSAHAr Exception caught: $e');
      rideStatus.value = 'error';
      Get.snackbar('Error', 'Failed to start ride: $e');
    } finally {
      isLoading.value = false;
      print('MRSAHAr Ride booking process completed');
    }
  }

  Future<void> _createMarkersAndPolylines() async {
    markers.clear();
    polylines.clear();
    isLoadingRoute.value = true;

    List<LatLng> routePoints = [];
    List<LatLng> waypoints = [];

    // Create pickup marker
    if (pickupLocation.value != null) {
      LatLng pickupLatLng = LatLng(
        pickupLocation.value!.latitude,
        pickupLocation.value!.longitude,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: pickupLocation.value!.address,
          ),
        ),
      );

      routePoints.add(pickupLatLng);
    }

    // Create additional stop markers and collect waypoints
    for (int i = 0; i < additionalStops.length; i++) {
      final stop = additionalStops[i];
      if (stop.address.isNotEmpty && stop.latitude != 0 && stop.longitude != 0) {
        LatLng stopLatLng = LatLng(stop.latitude, stop.longitude);

        markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: stopLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            infoWindow: InfoWindow(
              title: 'Stop ${i + 1}',
              snippet: stop.address,
            ),
          ),
        );

        waypoints.add(stopLatLng);
        routePoints.add(stopLatLng);
      }
    }

    // Create dropoff marker
    LatLng? dropoffLatLng;
    if (dropoffLocation.value != null) {
      dropoffLatLng = LatLng(
        dropoffLocation.value!.latitude,
        dropoffLocation.value!.longitude,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Dropoff Location',
            snippet: dropoffLocation.value!.address,
          ),
        ),
      );

      routePoints.add(dropoffLatLng);
    }

    // Create polylines with real routes using Google Directions API
    await _createRealRoutes(routePoints, waypoints, dropoffLatLng);

    isLoadingRoute.value = false;
  }

  Future<void> _createRealRoutes(List<LatLng> routePoints, List<LatLng> waypoints, LatLng? dropoffLatLng) async {
    if (routePoints.length < 2 || dropoffLatLng == null) return;

    try {
      LatLng origin = routePoints.first;
      LatLng destination = dropoffLatLng;

      // Get the optimized route using Google Directions API
      List<LatLng> routeCoordinates = await GoogleDirectionsService.getRoutePoints(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      );

      // Get route information
      Map<String, dynamic> routeInfo = await GoogleDirectionsService.getRouteInfo(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      );

      // Update route info
      routeDistance.value = routeInfo['distance'];
      routeDuration.value = routeInfo['duration'];

      if (routeInfo['status'] == 'OK') {
        // Create main polyline with all points
        polylines.add(
          Polyline(
            polylineId: const PolylineId('main_route'),
            points: routeCoordinates,
            color: Colors.blue,
            width: 5,
            patterns: [],
          ),
        );

        print(' MRSAHAr Route created successfully: ${routeDistance.value}, ${routeDuration.value}');
      } else {
        // Fallback to segment-by-segment routing if main route fails
        await _createSegmentRoutes(routePoints);
      }

    } catch (e) {
      print(' MRSAHAr Error creating real routes: $e');
      // Fallback to simple polylines
      await _createFallbackPolylines(routePoints);
    }
  }

  Future<void> _createSegmentRoutes(List<LatLng> routePoints) async {
    for (int i = 0; i < routePoints.length - 1; i++) {
      try {
        List<LatLng> segmentPoints = await GoogleDirectionsService.getRoutePoints(
          origin: routePoints[i],
          destination: routePoints[i + 1],
        );

        // Different colors for different segments
        Color segmentColor;
        List<PatternItem> patterns = [];

        if (i == 0) {
          segmentColor = Colors.blue; // First segment
        } else if (i == routePoints.length - 2) {
          segmentColor = Colors.red; // Last segment
          patterns = [PatternItem.dash(10), PatternItem.gap(5)];
        } else {
          segmentColor = Colors.orange; // Middle segments
          patterns = [PatternItem.dash(10), PatternItem.gap(5)];
        }

        polylines.add(
          Polyline(
            polylineId: PolylineId('segment_$i'),
            points: segmentPoints,
            color: segmentColor,
            width: 4,
            patterns: patterns,
          ),
        );

      } catch (e) {
        print(' MRSAHAr Error creating segment $i: $e');
        // Create fallback straight line for this segment
        _createFallbackSegment(routePoints[i], routePoints[i + 1], i);
      }
    }
  }

  void _createFallbackSegment(LatLng start, LatLng end, int index) {
    List<LatLng> segmentPoints = [];

    // Create simple straight line between points
    int segments = 20;
    for (int j = 0; j <= segments; j++) {
      double ratio = j / segments;
      double lat = start.latitude + (end.latitude - start.latitude) * ratio;
      double lng = start.longitude + (end.longitude - start.longitude) * ratio;
      segmentPoints.add(LatLng(lat, lng));
    }

    Color segmentColor = index == 0 ? Colors.blue : Colors.orange;

    polylines.add(
      Polyline(
        polylineId: PolylineId('fallback_segment_$index'),
        points: segmentPoints,
        color: segmentColor,
        width: 4,
        patterns: index == 0 ? [] : [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    );
  }

  Future<void> _createFallbackPolylines(List<LatLng> routePoints) async {
    for (int i = 0; i < routePoints.length - 1; i++) {
      _createFallbackSegment(routePoints[i], routePoints[i + 1], i);
    }

    // Set fallback route info
    routeDistance.value = 'Estimated';
    routeDuration.value = 'N/A';
  }

  // FIXED: Proper reset method
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
    searchSuggestions.clear();
    activeSearchField.value = '';
    routeDistance.value = '';
    routeDuration.value = '';
    currentRideId.value = '';
    rideStatus.value = 'pending';
  }

  void clearBooking() {
    markers.clear();
    polylines.clear();
    isRideBooked.value = false;
    resetForm();
  }

  // Start trip functionality
  Future<void> startTrip() async {
    if (currentRideId.value.isEmpty) {
      Get.snackbar('Error', 'Ride ID not found');
      return;
    }

    try {
      isLoading.value = true;

      Response response = await _apiProvider.postData('/api/Ride/${currentRideId.value}/start', {});

      if (response.isOk) {
        rideStatus.value = 'trip_started';
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

  // End trip functionality
  Future<void> endTrip() async {
    if (currentRideId.value.isEmpty) {
      Get.snackbar('Error', 'Ride ID not found');
      return;
    }

    try {
      isLoading.value = true;
      Response response = await _apiProvider.postData('/api/Ride/${currentRideId.value}/end', {});

      if (response.isOk) {
        var responseBody = response.body;
        print(' MRSAHAr End trip response: $responseBody');

        if (responseBody is Map<String, dynamic> && responseBody.containsKey('message')) {
          var messageData = responseBody['message'];

          if (messageData['status'] == 'Completed') {
            rideStatus.value = 'trip_completed';

            // Extract trip details
            String rideId = messageData['rideId'] ?? '';
            double finalFare = (messageData['finalFare'] ?? 0.0).toDouble();
            double distance = (messageData['distance'] ?? 0.0).toDouble();
            String rideStartTime = messageData['rideStartTime'] ?? '';
            String rideEndTime = messageData['rideEndTime'] ?? '';

            // Show payment popup
            _showPaymentPopup(
              rideId: rideId,
              finalFare: finalFare,
              distance: distance,
              rideStartTime: rideStartTime,
              rideEndTime: rideEndTime,
            );
          } else {
            Get.snackbar('Error', 'Trip completion failed: ${messageData['status']}');
          }
        } else {
          Get.snackbar('Trip Completed', 'Your trip has ended successfully!');
          Future.delayed(const Duration(seconds: 1), () {
            clearBooking();
          });
        }
      } else {
        Get.snackbar('Error', 'Failed to end trip: ${response.statusText}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to end trip: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showPaymentPopup({
    required String rideId,
    required double finalFare,
    required double distance,
    required String rideStartTime,
    required String rideEndTime,
    String? totalWaitingTime,
    String? status,
  }) {
    final theme = Theme.of(Get.context!);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trip Completed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status ?? 'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Trip details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt,
                            size: 24,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total Fare',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${finalFare.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Trip summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Distance', '${distance.toStringAsFixed(2)} km'),
                       // _buildSummaryItem('Duration', _calculateDuration(rideStartTime, rideEndTime)),
                        _buildSummaryItem('Waiting', totalWaitingTime ?? '0 min'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Get.back();
                            Get.snackbar('Payment', 'Payment of ₹${finalFare.toStringAsFixed(2)} completed!');
                            clearBooking();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Pay ₹${finalFare.toStringAsFixed(2)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            _showTipSelectionDialog(finalFare);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface,
                            foregroundColor: theme.colorScheme.surface,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Add Tip'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }




  void _showTipSelectionDialog(double finalFare) {
    final tipAmounts = [10.0, 15.0, 20.0];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Tip',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Show your appreciation',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              Column(
                children: tipAmounts.map((tipPercent) {
                  double tipAmount = finalFare * (tipPercent / 100);
                  double totalAmount = finalFare + tipAmount;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      color: Colors.grey[50],
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () async {
                          Get.back();
                          await _submitTip(tipAmount, finalFare, totalAmount);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${tipPercent.toInt()}% tip',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Payment', 'Payment of ₹${finalFare.toStringAsFixed(2)} completed!');
                    clearBooking();
                  },
                  child: Text(
                    'No Tip - Pay ₹${finalFare.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _submitTip(double tipAmount, double finalFare, double totalAmount) async {
    print(' MRSAHAr 🟡 _submitTip() called');
    print(' MRSAHAr 💰 Tip Amount: ₹${tipAmount.toStringAsFixed(2)}');
    print(' MRSAHAr 🧾 Final Fare: ₹${finalFare.toStringAsFixed(2)}');
    print(' MRSAHAr 📊 Total Amount: ₹${totalAmount.toStringAsFixed(2)}');

    try {
      isLoading.value = true;
      print(' MRSAHAr ⏳ isLoading set to true');

      Map<String, dynamic> tipData = {
        "rideId": currentRideId.value,
        "userId": "44f9ebba-b24d-4df1-8a60-bd7035b6097d",
        "amount": tipAmount,
        "createdAt": DateTime.now().toIso8601String(),
      };

      print(' MRSAHAr 📦 Tip Payload: $tipData');

      Response response = await _apiProvider.postData('/api/Tip', tipData);
      print(' MRSAHAr 📥 API Response: ${response.body}');

      if (response.isOk) {
        print(' MRSAHAr  MRSAHAr ✅ Tip submitted successfully');
        Get.snackbar(
          'Payment Successful',
          'Payment of ₹${totalAmount.toStringAsFixed(2)} (including ₹${tipAmount.toStringAsFixed(2)} tip) completed!',
          duration: Duration(seconds: 3),
        );
        clearBooking();
        print(' MRSAHAr  MRSAHAr 🧹 Booking cleared');
      } else {
        print(' MRSAHAr ❌ Tip submission failed: ${response.statusText}');
        Get.snackbar('Error', 'Failed to process tip: ${response.statusText}');
      }
    } catch (e) {
      print(' MRSAHAr 🔥 Exception during tip submission: $e');
      Get.snackbar('Error', 'Failed to process tip: $e');
    } finally {
      isLoading.value = false;
      print(' MRSAHAr ✅ isLoading set to false');
    }
  }


}
