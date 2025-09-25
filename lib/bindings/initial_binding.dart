// bindings/initial_binding.dart
import 'package:get/get.dart';
import 'package:pick_u/controllers/chat_controller.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/controllers/ride_controller.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/core/map_service.dart';
import 'package:pick_u/core/search_location_service.dart';
import 'package:pick_u/core/signalr_service.dart';
import 'package:pick_u/providers/api_provider.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.put(GlobalVariables(), permanent: true);
    Get.put<ApiProvider>(ApiProvider(), permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<RideController>(RideController(), permanent: true);
    Get.put<SearchService>(SearchService(), permanent: true);
    Get.put<MapService>(MapService(), permanent: true);
    Get.put<SignalRService>(SignalRService(), permanent: true);
    // Controllers
    Get.lazyPut<RideBookingController>(() => RideBookingController());
  }
}

