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

  // Map display variables
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isRideBooked = false.obs;

  // Route information
  var routeDistance = ''.obs;
  var routeDuration = ''.obs;
  var isLoadingRoute = false.obs;

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
      print('Error searching locations: $e');
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
      print('Error selecting suggestion: $e');
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

  Future<void> bookRide() async {
    if (pickupLocation.value == null || dropoffLocation.value == null) {
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return;
    }

    try {
      isLoading.value = true;

      // Create markers and polylines with real routes
      await _createMarkersAndPolylines();

      // Set ride as booked to show on map
      isRideBooked.value = true;

      List<RideStop> allStops = [];

      // Add pickup location
      allStops.add(RideStop(
        stopOrder: 0,
        location: pickupLocation.value!.address,
        latitude: pickupLocation.value!.latitude,
        longitude: pickupLocation.value!.longitude,
      ));

      // Add additional stops
      for (int i = 0; i < additionalStops.length; i++) {
        final stop = additionalStops[i];
        if (stop.address.isNotEmpty) {
          allStops.add(RideStop(
            stopOrder: i + 1,
            location: stop.address,
            latitude: stop.latitude,
            longitude: stop.longitude,
          ));
        }
      }

      // Add dropoff location
      allStops.add(RideStop(
        stopOrder: allStops.length,
        location: dropoffLocation.value!.address,
        latitude: dropoffLocation.value!.latitude,
        longitude: dropoffLocation.value!.longitude,
      ));

      RideRequest request = RideRequest(
        userId: "3fa85f64-5717-4562-b3fc-2c963f66afa6", // Replace with actual user ID
        rideType: rideType.value,
        isScheduled: false,
        passengerCount: passengerCount.value,
        fareEstimate: fareEstimate.value,
        stops: allStops,
      );

      Response response = await _apiProvider.postData('/api/Ride/book', request.toJson());

      if (response.isOk) {
        Get.snackbar(
          'Success',
          'Ride booked successfully!\nDistance: ${routeDistance.value}\nDuration: ${routeDuration.value}',
          duration: const Duration(seconds: 4),
        );
        Get.back(); // Go back to HomeScreen to show the route
      } else {
        Get.snackbar('Error', 'Failed to book ride: ${response.statusText}');
        isRideBooked.value = false; // Reset if booking fails
      }
    } catch (e) {
      Get.snackbar('Error', 'Booking failed: $e');
      isRideBooked.value = false; // Reset if booking fails
    } finally {
      isLoading.value = false;
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

        print('Route created successfully: ${routeDistance.value}, ${routeDuration.value}');
      } else {
        // Fallback to segment-by-segment routing if main route fails
        await _createSegmentRoutes(routePoints);
      }

    } catch (e) {
      print('Error creating real routes: $e');
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
        print('Error creating segment $i: $e');
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
  }

  void clearBooking() {
    markers.clear();
    polylines.clear();
    isRideBooked.value = false;
    resetForm();
  }

  void changeLocation() {
    // Implementation for changing location
  }

  Future<void> startRide() async {
    if (!isRideBooked.value) {
      Get.snackbar('Error', 'Please book a ride first');
      return;
    }

    Get.snackbar('Success', 'Ride started! Following your route...');
    // You can add additional ride start logic here
  }
}
