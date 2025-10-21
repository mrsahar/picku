import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:pick_u/models/location_model.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class LocationService extends GetxService {
  static LocationService get to => Get.find();

  var currentPosition = Rx<geo.Position?>(null);
  var currentLatLng = Rx<LatLng?>(null);
  var currentAddress = ''.obs;
  var isLocationLoading = false.obs;
  var isGpsEnabled = true.obs;

  StreamSubscription<geo.ServiceStatus>? _serviceStatusSubscription;
  Timer? _gpsCheckTimer;
  bool _isDialogShowing = false;

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
    _startGpsObserver();
  }

  @override
  void onClose() {
    _serviceStatusSubscription?.cancel();
    _gpsCheckTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeLocation() async {
    await getCurrentLocation();
  }

  void _startGpsObserver() {
    _serviceStatusSubscription = geo.Geolocator.getServiceStatusStream().listen(
      (geo.ServiceStatus status) {
        bool gpsEnabled = status == geo.ServiceStatus.enabled;
        _handleGpsStatusChange(gpsEnabled);
      },
      onError: (error) {
        print('Error listening to GPS status: $error');
        _startPeriodicGpsCheck();
      },
    );
    _startPeriodicGpsCheck();
  }

  /// Periodic GPS check as fallback
  void _startPeriodicGpsCheck() {
    _gpsCheckTimer?.cancel();
    _gpsCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      bool gpsEnabled = await geo.Geolocator.isLocationServiceEnabled();
      _handleGpsStatusChange(gpsEnabled);
    });
  }

  /// Handle GPS status changes
  void _handleGpsStatusChange(bool gpsEnabled) {
    if (isGpsEnabled.value != gpsEnabled) {
      isGpsEnabled.value = gpsEnabled;

      if (!gpsEnabled && !_isDialogShowing) {
        _showGpsDisabledDialog();
      } else if (gpsEnabled) {
        _triggerLocationListenerSetup();
      }
    }
  }

  /// Trigger location listener setup in home screen when GPS is enabled
  void _triggerLocationListenerSetup() {
    try {
      getCurrentLocation().then((_) {
        print('LocationService: GPS enabled - location updated and listeners notified');
      });
    } catch (e) {
      print('LocationService: Error triggering location listener setup: $e');
    }
  }

  void _showGpsDisabledDialog() {
    if (_isDialogShowing) return;

    _isDialogShowing = true;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: MColor.primaryNavy),
            SizedBox(width: 8),
            Text('GPS Required'),
          ],
        ),
        content: Text(
          'GPS is turned off. Please enable location services to use our services.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isDialogShowing = false;
              Get.back();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              _isDialogShowing = false;
              Get.back();
              await _openLocationSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  /// Open device location settings
  Future<void> _openLocationSettings() async {
    try {
      await geo.Geolocator.openLocationSettings();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open location settings. Please enable GPS manually.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  Future<geo.Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showGpsDisabledDialog();
        return null;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          Get.snackbar('Error', 'Location permission denied');
          return null;
        }
      }

      return await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: $e');
      return null;
    }
  }

  /// Get current location and update reactive variables
  Future<void> getCurrentLocation() async {
    isLocationLoading.value = true;
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        Get.snackbar('Permission Required', 'Location permission is required');
        return;
      }

      geo.Position? position = await getCurrentPosition();
      if (position != null) {
        currentPosition.value = position;
        currentLatLng.value = LatLng(position.latitude, position.longitude);

        String address = await getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        currentAddress.value = address;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
    } finally {
      isLocationLoading.value = false;
    }
  }

  /// Get LocationData object for current location
  LocationData? getCurrentLocationData() {
    if (currentPosition.value == null || currentAddress.value.isEmpty) {
      return null;
    }

    return LocationData(
      address: currentAddress.value,
      latitude: currentPosition.value!.latitude,
      longitude: currentPosition.value!.longitude,
      stopOrder: 0,
    );
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build address step by step, ensuring we always have something
        String street = place.street ?? place.thoroughfare ?? place.name ?? '';
        String locality = place.locality ?? place.subLocality ?? '';
        String area = place.administrativeArea ?? place.subAdministrativeArea ?? place.country ?? '';

        // Remove empty parts and join
        List<String> addressParts = [street, locality, area]
            .where((part) => part.isNotEmpty)
            .toList();

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    } catch (e) {
      print(' SAHArError getting address: $e');
    }

    // Instead of "Unknown location", return formatted coordinates
    return 'Location: ${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°';
  }

  Future<List<Location>> searchPlaces(String query) async {
    try {
      return await locationFromAddress(query);
    } catch (e) {
      print(' SAHArError searching places: $e');
      return [];
    }
  }

  /// Convert Position to LatLng
  LatLng? positionToLatLng(geo.Position? position) {
    if (position == null) return null;
    return LatLng(position.latitude, position.longitude);
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return geo.Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await geo.Geolocator.isLocationServiceEnabled();
  }

  /// Get location permission status
  Future<geo.LocationPermission> getPermissionStatus() async {
    return await geo.Geolocator.checkPermission();
  }
}