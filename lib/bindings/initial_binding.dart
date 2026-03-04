// bindings/initial_binding.dart
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/services/global_variables.dart';
import 'package:pick_u/providers/api_provider.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Minimal deps for login/splash. Location, map, SignalR, ride services are in MainMapBinding (no location permission on login).
    Get.put(GlobalVariables(), permanent: true);
    Get.put<ApiProvider>(ApiProvider(), permanent: true);
    Get.lazyPut<RideBookingController>(() => RideBookingController());
  }
}
