import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class LocationService extends GetxService {
  static LocationService get to => Get.find();

  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Error', 'Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Error', 'Location permission denied');
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: $e');
      return null;
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Unknown location';
  }

  Future<List<Location>> searchPlaces(String query) async {
    try {
      return await locationFromAddress(query);
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
}