import 'package:get/get.dart';
import 'package:pick_u/controllers/chat_controller.dart';
import 'package:pick_u/services/chat_background_service.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Register ChatBackgroundService as a service (singleton that persists)
    Get.put<ChatBackgroundService>(ChatBackgroundService(), permanent: true);

    // Register ChatController
    Get.lazyPut<ChatController>(() => ChatController());
  }
}