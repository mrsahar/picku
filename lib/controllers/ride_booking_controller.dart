import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/models/ride_models.dart';
import 'package:pick_u/providers/api_provider.dart';
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
  var searchSuggestions = <String>[].obs;
  var activeSearchField = ''.obs;
  var passengerCount = 1.obs;
  var rideType = 'standard'.obs;
  var fareEstimate = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
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
    if (query.length < 3) {
      searchSuggestions.clear();
      return;
    }

    activeSearchField.value = fieldType;

    // Mock suggestions - in production use Google Places API
    List<String> mockSuggestions = [
      '$query - Main Street, Peshawar',
      '$query - University Road, Peshawar',
      '$query - GT Road, Peshawar',
      '$query - Saddar, Peshawar',
      '$query - Hayatabad, Peshawar',
    ];
    searchSuggestions.value = mockSuggestions;
  }

  void selectSuggestion(String suggestion) {
    searchSuggestions.clear();

    // Mock coordinates
    double lat = currentPosition.value?.latitude ?? 31.8329711;
    double lng = currentPosition.value?.longitude ?? 70.9028416;

    if (activeSearchField.value == 'pickup') {
      pickupController.text = suggestion;
      pickupLocation.value = LocationData(
        address: suggestion,
        latitude: lat,
        longitude: lng,
        stopOrder: 0,
      );
    } else if (activeSearchField.value == 'dropoff') {
      dropoffController.text = suggestion;
      dropoffLocation.value = LocationData(
        address: suggestion,
        latitude: lat + 0.01,
        longitude: lng + 0.01,
        stopOrder: 1,
      );
    } else if (activeSearchField.value.startsWith('stop_')) {
      int stopIndex = int.parse(activeSearchField.value.split('_')[1]);
      if (stopIndex < stopControllers.length) {
        stopControllers[stopIndex].text = suggestion;

        LocationData stopData = LocationData(
          address: suggestion,
          latitude: lat + (0.005 * (stopIndex + 1)),
          longitude: lng + (0.005 * (stopIndex + 1)),
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
        Get.snackbar('Success', 'Ride booked successfully!');
        Get.back(); // Go back to HomeScreen
      } else {
        Get.snackbar('Error', 'Failed to book ride: ${response.statusText}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Booking failed: $e');
    } finally {
      isLoading.value = false;
    }
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
  }

  void changeLocation() {

  }

  Future<void> startRide() async {
    await bookRide();
  }
}
