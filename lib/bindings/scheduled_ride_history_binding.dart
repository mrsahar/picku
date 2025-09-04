import 'package:get/get.dart';
import 'package:pick_u/controllers/scheduled_ride_history_controller.dart';

class ScheduledRideHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScheduledRideHistoryController>(() => ScheduledRideHistoryController());
  }
}