import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/controllers/ride_controller.dart';
import 'package:pick_u/services/chat_background_service.dart';
import 'package:pick_u/services/global_variables.dart';
import 'package:pick_u/services/location_service.dart';
import 'package:pick_u/services/map_service.dart';
import 'package:pick_u/services/search_location_service.dart';
import 'package:pick_u/services/signalr_service.dart';
import 'package:pick_u/services/picku_background_service.dart';
import 'package:pick_u/providers/api_provider.dart';

class MainMapBinding extends Bindings {
  @override
  void dependencies() {
    // SignalR + ChatBackgroundService + ride background service only when user reaches MainMap (not on app open)
    if (!Get.isRegistered<SignalRService>()) {
      Get.put<SignalRService>(SignalRService(), permanent: true);
    }
    if (!Get.isRegistered<ChatBackgroundService>()) {
      Get.put<ChatBackgroundService>(ChatBackgroundService(), permanent: true);
    }
    initializeBackgroundService();

    // Location + map services only when user reaches MainMap (avoids location permission on login)
    if (!Get.isRegistered<LocationService>()) {
      Get.put<LocationService>(LocationService(), permanent: true);
    }
    if (!Get.isRegistered<MapService>()) {
      Get.put<MapService>(MapService(), permanent: true);
    }
    if (!Get.isRegistered<SearchService>()) {
      Get.put<SearchService>(SearchService(), permanent: true);
    }
    if (!Get.isRegistered<RideController>()) {
      Get.put<RideController>(RideController(), permanent: true);
    }

    // Ensure global deps
    if (!Get.isRegistered<GlobalVariables>()) {
      Get.put(GlobalVariables(), permanent: true);
    }

    if (!Get.isRegistered<ApiProvider>()) {
      Get.put<ApiProvider>(ApiProvider(), permanent: true);
    }

    if (!Get.isRegistered<RideBookingController>()) {
      Get.lazyPut<RideBookingController>(() => RideBookingController());
    }
  }
}

