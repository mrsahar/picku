import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/core/google_directions_service.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class MapService extends GetxService {
  static MapService get to => Get.find();

  // Observable variables
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingRoute = false.obs;
  var routeDistance = ''.obs;
  var routeDuration = ''.obs;

  GoogleMapController? mapController;

  // Custom marker icons
  BitmapDescriptor? _userMarkerIcon;
  BitmapDescriptor? _driverMarkerIcon;
  BitmapDescriptor? _pointsMarkerIcon;

  @override
  void onInit() {
    super.onInit();
    _initializeCustomMarkers();
  }

  /// Initialize custom marker icons
  Future<void> _initializeCustomMarkers() async {
    try {
      print('Loading custom marker icons...');

      _userMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/user.png',
      );
      print('User marker icon loaded successfully');

      _driverMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/taxi.png',
      );
      print('Driver marker icon loaded successfully');

      _pointsMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/points.png',
      );
      print('Points marker icon loaded successfully');

    } catch (e) {
      print('Error loading custom marker icons: $e');
      print('Will use default markers as fallback');
      // Fallback to default markers if custom ones fail to load
    }
  }

  /// Set the map controller
  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  /// Create markers and polylines for a route
  Future<void> createRouteMarkersAndPolylines({
    required LocationData? pickupLocation,
    required LocationData? dropoffLocation,
    required List<LocationData> additionalStops,
  }) async {
    markers.clear();
    polylines.clear();
    isLoadingRoute.value = true;

    try {
      List<LatLng> routePoints = [];
      List<LatLng> waypoints = [];

      // Create pickup marker
      if (pickupLocation != null) {
        LatLng pickupLatLng = LatLng(pickupLocation.latitude, pickupLocation.longitude);

        markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: _pointsMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: pickupLocation.address,
          ),
        ));

        routePoints.add(pickupLatLng);
      }

      // Create additional stop markers
      for (int i = 0; i < additionalStops.length; i++) {
        final stop = additionalStops[i];
        if (stop.address.isNotEmpty && stop.latitude != 0 && stop.longitude != 0) {
          LatLng stopLatLng = LatLng(stop.latitude, stop.longitude);

          markers.add(Marker(
            markerId: MarkerId('stop_$i'),
            position: stopLatLng,
            icon: _pointsMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            infoWindow: InfoWindow(
              title: 'Stop ${i + 1}',
              snippet: stop.address,
            ),
          ));

          waypoints.add(stopLatLng);
          routePoints.add(stopLatLng);
        }
      }

      // Create dropoff marker
      LatLng? dropoffLatLng;
      if (dropoffLocation != null) {
        dropoffLatLng = LatLng(dropoffLocation.latitude, dropoffLocation.longitude);

        markers.add(Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          icon: _pointsMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Dropoff Location',
            snippet: dropoffLocation.address,
          ),
        ));

        routePoints.add(dropoffLatLng);
      }

      // Create route polylines
      if (routePoints.length >= 2 && dropoffLatLng != null) {
        await _createRoutePolylines(routePoints, waypoints, dropoffLatLng);
      }

    } catch (e) {
      print('Error creating route markers and polylines: $e');
      Get.snackbar('Route Error', 'Failed to create route visualization');
    } finally {
      isLoadingRoute.value = false;
    }
  }

  /// Create route polylines using Google Directions API
  Future<void> _createRoutePolylines(
      List<LatLng> routePoints,
      List<LatLng> waypoints,
      LatLng destination
      ) async {
    try {
      LatLng origin = routePoints.first;

      // Get route coordinates from Google Directions
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
        // Create main polyline
        polylines.add(Polyline(
          polylineId: const PolylineId('main_route'),
          points: routeCoordinates,
          color: MColor.primaryNavy,
          width: 5,
        ));
      } else {
        // Fallback to segment routing
        await _createSegmentRoutes(routePoints);
      }
    } catch (e) {
      print('Error creating route polylines: $e');
      await _createFallbackPolylines(routePoints);
    }
  }

  /// Create segment-by-segment routes as fallback
  Future<void> _createSegmentRoutes(List<LatLng> routePoints) async {
    for (int i = 0; i < routePoints.length - 1; i++) {
      try {
        List<LatLng> segmentPoints = await GoogleDirectionsService.getRoutePoints(
          origin: routePoints[i],
          destination: routePoints[i + 1],
        );

        Color segmentColor = i == 0 ? Colors.blue : Colors.orange;
        List<PatternItem> patterns = i == 0 ? [] : [PatternItem.dash(10), PatternItem.gap(5)];

        polylines.add(Polyline(
          polylineId: PolylineId('segment_$i'),
          points: segmentPoints,
          color: segmentColor,
          width: 4,
          patterns: patterns,
        ));
      } catch (e) {
        print('Error creating segment $i: $e');
        _createFallbackSegment(routePoints[i], routePoints[i + 1], i);
      }
    }
  }

  /// Create fallback straight line polylines
  Future<void> _createFallbackPolylines(List<LatLng> routePoints) async {
    for (int i = 0; i < routePoints.length - 1; i++) {
      _createFallbackSegment(routePoints[i], routePoints[i + 1], i);
    }
    routeDistance.value = 'Estimated';
    routeDuration.value = 'N/A';
  }

  /// Create a straight line segment as fallback
  void _createFallbackSegment(LatLng start, LatLng end, int index) {
    List<LatLng> segmentPoints = [];
    int segments = 20;

    for (int j = 0; j <= segments; j++) {
      double ratio = j / segments;
      double lat = start.latitude + (end.latitude - start.latitude) * ratio;
      double lng = start.longitude + (end.longitude - start.longitude) * ratio;
      segmentPoints.add(LatLng(lat, lng));
    }

    Color segmentColor = index == 0 ? Colors.blue : Colors.orange;

    polylines.add(Polyline(
      polylineId: PolylineId('fallback_segment_$index'),
      points: segmentPoints,
      color: segmentColor,
      width: 4,
      patterns: index == 0 ? [] : [PatternItem.dash(10), PatternItem.gap(5)],
    ));
  }

  /// Create or update driver marker
  void updateDriverMarker(double lat, double lng, String driverName) {
    final driverMarker = Marker(
      markerId: const MarkerId('driver_location'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: 'Driver: $driverName',
        snippet: 'Coming to pick you up',
      ),
      icon: _driverMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    // Remove existing driver marker and add new one
    markers.removeWhere((marker) => marker.markerId.value == 'driver_location');
    markers.add(driverMarker);
  }

  /// Animate camera to specific location
  Future<void> animateToLocation(LatLng location, {double zoom = 16.0}) async {
    if (mapController == null) return;

    try {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: zoom),
        ),
      );
    } catch (e) {
      print('Error animating to location: $e');
    }
  }

  /// Show pickup location with zoom effect
  Future<void> showPickupLocationWithZoom(LocationData? pickupLocation) async {
    if (pickupLocation == null || mapController == null) {
      Get.snackbar('Error', 'No pickup location or map not ready');
      return;
    }

    try {
      final pickupLatLng = LatLng(pickupLocation.latitude, pickupLocation.longitude);

      // Create pickup marker
      _createPickupMarker(pickupLocation);

      // Dramatic zoom effect
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pickupLatLng, zoom: 10.0),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));

      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pickupLatLng,
            zoom: 17.5,
            tilt: 60.0,
            bearing: 45.0,
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));

      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pickupLatLng, zoom: 16.5),
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to show pickup location: $e');
    }
  }

  /// Create pickup marker
  void _createPickupMarker(LocationData pickupLocation) {
    final pickupMarker = Marker(
      markerId: const MarkerId('pickup_location'),
      position: LatLng(pickupLocation.latitude, pickupLocation.longitude),
      infoWindow: InfoWindow(
        title: 'Pickup Location',
        snippet: pickupLocation.address,
      ),
      icon: _pointsMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    markers.removeWhere((marker) => marker.markerId.value == 'pickup_location');
    markers.add(pickupMarker);
  }

  /// Fit map to show multiple locations
  Future<void> fitMapToLocations(List<LatLng> locations) async {
    if (mapController == null || locations.isEmpty) return;

    try {
      if (locations.length == 1) {
        await animateToLocation(locations.first, zoom: 15);
        return;
      }

      // Calculate bounds
      double minLat = locations.first.latitude;
      double maxLat = locations.first.latitude;
      double minLng = locations.first.longitude;
      double maxLng = locations.first.longitude;

      for (LatLng location in locations) {
        minLat = math.min(minLat, location.latitude);
        maxLat = math.max(maxLat, location.latitude);
        minLng = math.min(minLng, location.longitude);
        maxLng = math.max(maxLng, location.longitude);
      }

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 120.0),
      );
    } catch (e) {
      print('Error fitting map to locations: $e');
    }
  }

  /// Clear all markers and polylines
  void clearMap() {
    markers.clear();
    polylines.clear();
    routeDistance.value = '';
    routeDuration.value = '';
  }

  /// Add or update user location marker
  void updateUserLocationMarker(double lat, double lng, {String title = 'Your Location'}) {
    print('Adding user location marker at: $lat, $lng');
    print('Using custom user icon: ${_userMarkerIcon != null}');

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: title,
        snippet: 'Current location',
      ),
      icon: _userMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    // Remove existing user marker and add new one
    markers.removeWhere((marker) => marker.markerId.value == 'user_location');
    markers.add(userMarker);
    print('User location marker added. Total markers: ${markers.length}');
  }

  /// Get custom marker icons (for external use if needed)
  BitmapDescriptor? get userMarkerIcon => _userMarkerIcon;
  BitmapDescriptor? get driverMarkerIcon => _driverMarkerIcon;
  BitmapDescriptor? get pointsMarkerIcon => _pointsMarkerIcon;
}
