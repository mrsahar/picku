import 'package:get/get.dart';
import 'package:pick_u/controllers/driver_admin_chat_controller.dart';

class HelpCenterBinding extends Bindings {
  @override
  void dependencies() {
    // Register DriverAdminChatController
    Get.lazyPut<DriverAdminChatController>(() => DriverAdminChatController());
  }
}

