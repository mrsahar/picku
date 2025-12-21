// bindings/initial_binding.dart
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/controllers/ride_controller.dart';
import 'package:pick_u/services/chat_background_service.dart';
import 'package:pick_u/services/global_variables.dart';
import 'package:pick_u/services/location_service.dart';
import 'package:pick_u/services/map_service.dart';
import 'package:pick_u/services/search_location_service.dart';
import 'package:pick_u/services/signalr_service.dart';
import 'package:pick_u/providers/api_provider.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.put(GlobalVariables(), permanent: true);
    Get.put<ApiProvider>(ApiProvider(), permanent: true);
    Get.put<SignalRService>(SignalRService(), permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<RideController>(RideController(), permanent: true);
    Get.put<SearchService>(SearchService(), permanent: true);
    Get.put<MapService>(MapService(), permanent: true);
    Get.put<ChatBackgroundService>(ChatBackgroundService(), permanent: true);
    // Controllers
    Get.lazyPut<RideBookingController>(() => RideBookingController());
  }
}
