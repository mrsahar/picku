import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/models/ride_models.dart';
import 'package:pick_u/providers/api_provider.dart';

class RideController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final LocationService _locationService = Get.find<LocationService>();

  // Observable variables
  var isLoading = false.obs;
  var currentPosition = Rx<Position?>(null);
  var currentAddress = ''.obs;
  var destinationAddress = ''.obs;
  var passengerCount = 1.obs;
  var rideType = 'standard'.obs;
  var fareEstimate = 0.0.obs;
  var stops = <RideStop>[].obs;
  var isMultiStopRide = false.obs;
  var markers = <Marker>{}.obs;

  // Camera controller for map
  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> getCurrentLocation() async {
    isLoading.value = true;
    try {
      bool hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        Get.snackbar('Permission Required', 'Location permission is required for this feature');
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
        currentAddress.value = address;
        _updateCurrentLocationMarker();
        _moveMapToCurrentLocation();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _updateCurrentLocationMarker() {
    if (currentPosition.value != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'current');
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(
            currentPosition.value!.latitude,
            currentPosition.value!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Current Location', snippet: currentAddress.value),
        ),
      );
    }
  }

  void _moveMapToCurrentLocation() {
    if (mapController != null && currentPosition.value != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentPosition.value!.latitude,
              currentPosition.value!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  Future<void> onMapTap(LatLng position) async {
    String address = await _locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (!isMultiStopRide.value) {
      // Single destination ride
      updateDestination(address, position.latitude, position.longitude);
    } else {
      // Multi-stop ride - add as additional stop
      addStop(address, position.latitude, position.longitude);
    }
  }

  void updateDestination(String address, double lat, double lng) {
    destinationAddress.value = address;

    // Remove existing destination marker
    markers.removeWhere((marker) => marker.markerId.value == 'destination');

    // Add new destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: address),
      ),
    );

    // Clear existing stops and set destination as first stop
    stops.clear();
    stops.add(RideStop(
      stopOrder: 0,
      location: address,
      latitude: lat,
      longitude: lng,
    ));
  }

  void addStop(String location, double lat, double lng) {
    final stopOrder = stops.length;
    stops.add(RideStop(
      stopOrder: stopOrder,
      location: location,
      latitude: lat,
      longitude: lng,
    ));

    // Add marker for the stop
    markers.add(
      Marker(
        markerId: MarkerId('stop_$stopOrder'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: 'Stop ${stopOrder + 1}', snippet: location),
      ),
    );
  }

  void removeStop(int index) {
    if (index < stops.length) {
      // Remove marker
      markers.removeWhere((marker) => marker.markerId.value == 'stop_$index');

      stops.removeAt(index);
      // Update stop orders and markers
      for (int i = 0; i < stops.length; i++) {
        stops[i].stopOrder = i;
      }
      _updateStopMarkers();
    }
  }

  void _updateStopMarkers() {
    // Remove all stop markers
    markers.removeWhere((marker) => marker.markerId.value.startsWith('stop_'));

    // Re-add updated markers
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: i == 0
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
            title: i == 0 ? 'Destination' : 'Stop ${i + 1}',
            snippet: stop.location,
          ),
        ),
      );
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

  Future<void> bookRide() async {
    if (currentPosition.value == null) {
      Get.snackbar('Error', 'Current location not available');
      return;
    }

    if (stops.isEmpty) {
      Get.snackbar('Error', 'Please select a destination');
      return;
    }

    try {
      isLoading.value = true;

      // Create pickup location as first stop
      List<RideStop> allStops = [];

      // Add current location as pickup (stop order 0)
      allStops.add(RideStop(
        stopOrder: 0,
        location: currentAddress.value,
        latitude: currentPosition.value!.latitude,
        longitude: currentPosition.value!.longitude,
      ));

      // Add all destination/stops with updated order
      for (int i = 0; i < stops.length; i++) {
        stops[i].stopOrder = i + 1;
        allStops.add(stops[i]);
      }

      RideRequest request = RideRequest(
        userId: "3fa85f64-5717-4562-b3fc-2c963f66afa6", // Replace with actual user ID
        rideType: rideType.value,
        isScheduled: false,
        passengerCount: passengerCount.value,
        fareEstimate: fareEstimate.value,
        stops: allStops,
      );

      Response response = await _apiProvider.postData('/api/rides', request.toJson());

      if (response.isOk) {
        Get.snackbar('Success', 'Ride booked successfully!');
        // You can trigger widget transition here if needed
      } else {
        Get.snackbar('Error', 'Failed to book ride: ${response.statusText}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Booking failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void resetBookingForm() {
    stops.clear();
    destinationAddress.value = '';
    passengerCount.value = 1;
    fareEstimate.value = 0.0;
    isMultiStopRide.value = false;
    // Clear destination and stop markers, keep current location
    markers.removeWhere((marker) =>
    marker.markerId.value != 'current'
    );
  }

  void incrementPassengers() {
    if (passengerCount.value < 8) {
      passengerCount.value++;
    }
  }

  void decrementPassengers() {
    if (passengerCount.value > 1) {
      passengerCount.value--;
    }
  }
}