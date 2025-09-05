import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/models/forgot_password_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import '../routes/app_routes.dart';

class ForgotPasswordController extends GetxController {
  // Form controller
  final emailController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Loading state
  final isLoading = false.obs;

  // API Provider
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
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

  // Manual validation
  bool validateForm() {
    return validateEmail(emailController.text) == null;
  }

  // Forgot password method
  Future<void> forgotPassword() async {
    if (!validateForm()) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid email address',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      isLoading.value = true;

      final forgotPasswordRequest = ForgotPasswordRequest(
        email: emailController.text.trim(),
      );

      print('MRSAHAr 📤 ForgotPassword: Sending request for email: ${emailController.text}');
      final response = await _apiProvider.forgotPassword(forgotPasswordRequest);

      print('MRSAHAr 📥 ForgotPassword: Response received - Success: ${response.success}');

      if (response.success) {
        final globalVars = GlobalVariables.instance;
        globalVars.setUserEmail(emailController.text.trim());
        Get.snackbar(
          'Success',
          response.message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        // You can modify this based on your flow
        Get.toNamed(AppRoutes.Reset_Password, arguments: {
          'email': emailController.text.trim(),
          'isFromForgotPassword': true, // Flag to indicate this is from forgot password
        });

      } else {
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e, stackTrace) {
      print('MRSAHAr 💥 ForgotPassword: Exception caught: $e');
      print('MRSAHAr 📍 ForgotPassword: Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to send reset email. Please try again.',
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
  }

  // Navigate back to login
  void goBackToLogin() {
    Get.back();
  }
}