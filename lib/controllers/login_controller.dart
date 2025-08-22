import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/providers/api_provider.dart';
import '../models/login_model.dart';
import '../routes/app_routes.dart';

class LoginController extends GetxController {

  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  // Form key
  final formKey = GlobalKey<FormState>();

  // Loading state
  final isLoading = false.obs;

  // Password visibility
  final isPasswordVisible = false.obs;

  // API Provider
  late final ApiProvider _apiProvider;

  @override
  void onInit() {
    super.onInit();
    // Initialize controllers here
    emailController = TextEditingController();
    passwordController = TextEditingController();
    // Initialize API provider
    _apiProvider = Get.find<ApiProvider>();
  }

  @override
  void onClose() {
    // Dispose controllers when controller is destroyed
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Get device token
  String getDeviceToken() {
    // For now, return a placeholder. You should implement:
    // - Firebase FCM token
    // - Device ID
    // - Or any unique device identifier
    return "deviceToken_placeholder_${DateTime.now().millisecondsSinceEpoch}";
  }

  // Login method - use Form validation instead of manual validation
  Future<void> login(BuildContext context) async {
    // Use formKey.currentState!.validate() instead of manual validation
    if (!formKey.currentState!.validate()) {
      return; // Form validation will show error messages automatically
    }

    try {
      isLoading.value = true;

      final loginRequest = LoginRequest(
        email: emailController.text.trim(),
        password: passwordController.text,
        deviceToken: getDeviceToken(),
      );

      print('📤 Login: Sending request for email: ${emailController.text}');
      final response = await _apiProvider.login(loginRequest);

      if (response.success) {
        // Save user data in GlobalVariables
        final globalVars = GlobalVariables.instance;
        globalVars.setUserEmail(emailController.text.trim());
        globalVars.setLoginStatus(true);

        // If API returns token, save it
        if (response.data != null && response.data['token'] != null) {
          globalVars.setUserToken(response.data['token']);
        }

        // Clear form on success
        clearForm();

        Get.snackbar(
          'Success',
          response.message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        // Navigate to Dashboard or Home screen
        Get.offAllNamed(AppRoutes.MainMap);
      } else {
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('💥 Login: Error: $e');
      Get.snackbar(
        'Error',
        'Failed to login. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Clear form
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    isPasswordVisible.value = false;
  }
}

// Updated LoginBinding to ensure proper initialization
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}