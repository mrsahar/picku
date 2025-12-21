import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/services/google_directions_service.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class MapService extends GetxService {
  static MapService get to => Get.find();

  // Observable variables
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingRoute = false.obs;
  var routeDistance = ''.obs;
  var routeDuration = ''.obs;
  final List<LatLng> _interpolationPoints = [];
  int _interpolationIndex = 0;

  GoogleMapController? mapController;

  // Custom marker icons
  BitmapDescriptor? _userMarkerIcon;
  BitmapDescriptor? _driverMarkerIcon;
  BitmapDescriptor? _pointsMarkerIcon;

  // Driver animation variables with route following
  List<LatLng> _currentRoutePolyline = [];
  int _currentPolylineIndex = 0;
  LatLng? _previousDriverLocation;
  Timer? _animationTimer;
  final int _animationSteps = 120;
  int _currentAnimationStep = 0;
  bool _isAnimating = false;

  @override
  void onInit() {
    super.onInit();
    _initializeCustomMarkers();
  }

  /// Initialize custom marker icons
  Future<void> _initializeCustomMarkers() async {
    try {
      print(' SAHArLoading custom marker icons...');

      _userMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/user.png',
      );
      print(' SAHArUser marker icon loaded successfully');

      _driverMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30 , 58)),
        'assets/img/taxi.png',
      );
      print(' SAHArDriver marker icon loaded successfully');

      _pointsMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/points.png',
      );
      print(' SAHArPoints marker icon loaded successfully');

    } catch (e) {
      print(' SAHArError loading custom marker icons: $e');
      print(' SAHArWill use default markers as fallback');
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
      print(' SAHArError creating route markers and polylines: $e');
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

      // Store the route polyline for car rotation calculations
      _currentRoutePolyline = routeCoordinates;
      _currentPolylineIndex = 0;

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
      print(' SAHArError creating route polylines: $e');
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
        print(' SAHArError creating segment $i: $e');
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

  /// Enhanced method to create or update driver marker with smooth animation
  void updateDriverMarkerWithAnimation(double lat, double lng, String driverName, {bool centerMap = true}) {
    final newLocation = LatLng(lat, lng);

    print(' SAHArSAHAR Updating driver location: $lat, $lng');
    print(' SAHArSAHAR Driver marker icon available: ${_driverMarkerIcon != null}');

    // Always create/update the marker immediately for first location
    if (_previousDriverLocation == null) {
      double bearing = _getBearingForLocation(newLocation);
      _createDriverMarker(newLocation, driverName, bearing);
      _previousDriverLocation = newLocation;

      // Force center map on first driver location
      if (centerMap) {
        Future.delayed(const Duration(milliseconds: 500), () {
          animateToLocation(newLocation, zoom: 16.0);
        });
      }

      print(' SAHArSAHAR First driver marker created at: $lat, $lng');
      return;
    }

    // For subsequent updates, animate if location changed
    if (_previousDriverLocation != newLocation) {
      if (centerMap) {
        animateToLocation(newLocation, zoom: 16.0);
      }

      // Use route-following animation for movement
      _startDriverAnimationWithRouteFollowing(_previousDriverLocation!, newLocation, driverName);
      _previousDriverLocation = newLocation;
    } else {
      // Same location, just ensure marker exists
      double bearing = _getBearingForLocation(newLocation);
      _createDriverMarker(newLocation, driverName, bearing);
    }
  }

  // REPLACE your existing _startDriverAnimationWithRouteFollowing method with this:
  void _startUltraSmoothDriverAnimation(LatLng fromLocation, LatLng toLocation, String driverName) {
    if (_animationTimer?.isActive ?? false) {
      _animationTimer?.cancel();
    }

    _isAnimating = true;
    _currentAnimationStep = 0;

    // Create interpolation points for ultra-smooth movement
    _createInterpolationPoints(fromLocation, toLocation);

    // Higher frequency timer for smoother animation (16ms ≈ 60fps)
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _currentAnimationStep++;

      double progress = _currentAnimationStep / _animationSteps;
      double easedProgress = _easeInOutQuint(progress);

      LatLng currentPosition = _getInterpolatedPosition(easedProgress);
      double bearing = _getSmoothBearing(fromLocation, toLocation, easedProgress);

      _createDriverMarkerWithRotation(currentPosition, driverName, bearing);

      if (_currentAnimationStep >= _animationSteps) {
        timer.cancel();
        _isAnimating = false;

        double finalBearing = _getBearingForLocation(toLocation);
        _createDriverMarkerWithRotation(toLocation, driverName, finalBearing);

        print(' SAHArSAHAR Ultra-smooth driver animation completed');
      }
    });
  }

  // ADD these new helper methods:
  void _createInterpolationPoints(LatLng from, LatLng to) {
    _interpolationPoints.clear();

    int numPoints = 100;

    for (int i = 0; i <= numPoints; i++) {
      double t = i / numPoints;
      double smoothT = _smoothStep(t);

      double lat = from.latitude + (to.latitude - from.latitude) * smoothT;
      double lng = from.longitude + (to.longitude - from.longitude) * smoothT;

      _interpolationPoints.add(LatLng(lat, lng));
    }
  }

  LatLng _getInterpolatedPosition(double progress) {
    if (_interpolationPoints.isEmpty) {
      return _previousDriverLocation ?? LatLng(0, 0);
    }

    int index = (progress * (_interpolationPoints.length - 1)).round();
    index = index.clamp(0, _interpolationPoints.length - 1);

    return _interpolationPoints[index];
  }

  double _getSmoothBearing(LatLng from, LatLng to, double progress) {
    if (_currentRoutePolyline.isNotEmpty) {
      LatLng currentPos = _getInterpolatedPosition(progress);
      return _getBearingForLocation(currentPos);
    }

    return _calculateBearingBetweenPoints(from, to);
  }

  double _easeInOutQuint(double t) {
    return t < 0.5
        ? 16 * t * t * t * t * t
        : 1 - math.pow(-2 * t + 2, 5) / 2;
  }

  double _smoothStep(double t) {
    return t * t * (3.0 - 2.0 * t);
  }

  /// Get bearing for a location based on the route polyline
  double _getBearingForLocation(LatLng location) {
    if (_currentRoutePolyline.isEmpty) {
      return 0.0; // Default bearing (north)
    }

    // Find the closest point on the route polyline
    int closestIndex = _findClosestPolylineIndex(location);

    // Get bearing from the road direction at this point
    return _getRoadBearingAtIndex(closestIndex);
  }

  /// Find the closest point on the route polyline
  int _findClosestPolylineIndex(LatLng location) {
    if (_currentRoutePolyline.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _currentRoutePolyline.length; i++) {
      double distance = _calculateDistanceBetweenPoints(location, _currentRoutePolyline[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Get road bearing at a specific polyline index
  double _getRoadBearingAtIndex(int index) {
    if (_currentRoutePolyline.length < 2) return 0.0;

    // Use next point for forward direction, or previous point if at end
    LatLng currentPoint = _currentRoutePolyline[index];
    LatLng targetPoint;

    if (index < _currentRoutePolyline.length - 1) {
      // Look ahead
      targetPoint = _currentRoutePolyline[index + 1];
    } else if (index > 0) {
      // Look back (we're at the end)
      LatLng previousPoint = _currentRoutePolyline[index - 1];
      targetPoint = currentPoint;
      currentPoint = previousPoint;
    } else {
      return 0.0;
    }

    return _calculateBearingBetweenPoints(currentPoint, targetPoint);
  }

  /// Start smooth animation for driver marker with route-following rotation
  void _startDriverAnimationWithRouteFollowing(LatLng fromLocation, LatLng toLocation, String driverName) {
    if (_animationTimer?.isActive ?? false) {
      _animationTimer?.cancel();
    }

    _isAnimating = true;
    _currentAnimationStep = 0;

    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _currentAnimationStep++;

      // Calculate progress (0.0 to 1.0)
      double progress = _currentAnimationStep / _animationSteps;

      // Use easing function for smoother animation
      double easedProgress = _easeInOutCubic(progress);

      // Interpolate position
      double lat = fromLocation.latitude +
          (toLocation.latitude - fromLocation.latitude) * easedProgress;
      double lng = fromLocation.longitude +
          (toLocation.longitude - fromLocation.longitude) * easedProgress;

      LatLng currentPosition = LatLng(lat, lng);

      // Calculate bearing based on route polyline, not straight line
      double bearing = _getBearingForLocation(currentPosition);

      // Create animated marker with route-based rotation
      _createDriverMarkerWithRotation(currentPosition, driverName, bearing);

      // Animation complete
      if (_currentAnimationStep >= _animationSteps) {
        timer.cancel();
        _isAnimating = false;

        // Ensure final position uses accurate road bearing
        double finalBearing = _getBearingForLocation(toLocation);
        _createDriverMarkerWithRotation(toLocation, driverName, finalBearing);

        print(' SAHArSAHAr Driver animation completed with road-following rotation');
      }
    });
  }

  /// Calculate bearing between two points (corrected formula)
  double _calculateBearingBetweenPoints(LatLng start, LatLng end) {
    double lat1Rad = start.latitude * (math.pi / 180);
    double lat2Rad = end.latitude * (math.pi / 180);
    double deltaLonRad = (end.longitude - start.longitude) * (math.pi / 180);

    double y = math.sin(deltaLonRad) * math.cos(lat2Rad);
    double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);

    double bearingRad = math.atan2(y, x);
    double bearingDeg = bearingRad * (180 / math.pi);

    // Normalize to 0-360 degrees
    return (bearingDeg + 360) % 360;
  }

  /// Calculate distance between two points in meters
  double _calculateDistanceBetweenPoints(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLonRad = (point2.longitude - point1.longitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Easing function for smooth animation
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
  }

  /// Create driver marker with rotation
  void _createDriverMarkerWithRotation(LatLng position, String driverName, double rotation) {
    final driverMarker = Marker(
      markerId: const MarkerId('driver_location'),
      position: position,
      rotation: rotation,
      infoWindow: InfoWindow(
        title: 'Driver: $driverName',
        snippet: 'Following route',
      ),
      icon: _driverMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      anchor: const Offset(0.5, 0.5), // Center the rotation
    );

    // Remove existing driver marker and add new one
    markers.removeWhere((marker) => marker.markerId.value == 'driver_location');
    markers.add(driverMarker);
  }

  /// Create simple driver marker without animation
  void _createDriverMarker(LatLng position, String driverName, double bearing) {
    final driverMarker = Marker(
      markerId: const MarkerId('driver_location'),
      position: position,
      rotation: bearing,
      infoWindow: InfoWindow(
        title: 'Driver: $driverName',
        snippet: 'On route to you',
      ),
      icon: _driverMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      anchor: const Offset(0.5, 0.5),
    );

    markers.removeWhere((marker) => marker.markerId.value == 'driver_location');
    markers.add(driverMarker);
  }

  /// Legacy method - kept for backward compatibility
  void updateDriverMarker(double lat, double lng, String driverName) {
    updateDriverMarkerWithAnimation(lat, lng, driverName, centerMap: true);
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
      print(' SAHArError animating to location: $e');
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
          CameraPosition(target: pickupLatLng, zoom: 14.0),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));

      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pickupLatLng,
            zoom: 17,
          ),
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
      print(' SAHArError fitting map to locations: $e');
    }
  }

  /// Clear all markers and polylines except user marker
  void clearMap() {
    _animationTimer?.cancel();
    _isAnimating = false;
    _previousDriverLocation = null;
    _currentAnimationStep = 0;
    // Don't reset custom marker icons - keep them loaded
    // _driverMarkerIcon = null;
    // _pointsMarkerIcon = null;

    _interpolationPoints.clear();
    _interpolationIndex = 0;

    _currentRoutePolyline.clear();
    _currentPolylineIndex = 0;

    // Remove all markers except user location marker
    markers.removeWhere((marker) => marker.markerId.value != 'user_location');

    polylines.clear();
    routeDistance.value = '';
    routeDuration.value = '';
  }

  /// Add or update user location marker
  void updateUserLocationMarker(double lat, double lng, {String title = 'Your Location'}) {
    print(' SAHArAdding user location marker at: $lat, $lng');
    print(' SAHArUsing custom user icon: ${_userMarkerIcon != null}');

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
    print(' SAHArUser location marker added. Total markers: ${markers.length}');
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    super.onClose();
  }

  /// Get custom marker icons (for external use if needed)
  BitmapDescriptor? get userMarkerIcon => _userMarkerIcon;
  BitmapDescriptor? get driverMarkerIcon => _driverMarkerIcon;
  BitmapDescriptor? get pointsMarkerIcon => _pointsMarkerIcon;
}
