// controllers/reset_password_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/models/reset_password_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/routes/app_routes.dart';

class ResetPasswordController extends GetxController {
  // Store the complete OTP
  final completeOTP = ''.obs;

  // Password controller
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Email from previous screen (passed as argument)
  final email = ''.obs;

  // Loading state
  final isLoading = false.obs;

  // Password visibility
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // API Provider
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  @override
  void onInit() {
    super.onInit();

    // Get email from GlobalVariables first (primary method)
    final globalVars = GlobalVariables.instance;
    if (globalVars.hasUserEmail) {
      email.value = globalVars.userEmail;
      print(' SAHArSAHAr 📧 ResetPassword: Got email from GlobalVariables: ${email.value}');
    } else {
      // Fallback: Get email from arguments (backup method)
      final args = Get.arguments;
      if (args != null && args['email'] != null) {
        email.value = args['email'];
        print(' SAHArSAHAr 📧 ResetPassword: Got email from arguments: ${email.value}');
      } else {
        print(' SAHArSAHAr ❌ ResetPassword: No email found in GlobalVariables or arguments');
      }
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Set complete OTP from OtpTextField
  void setCompleteOTP(String otp) {
    completeOTP.value = otp;
  }

  // Toggle password visibility
  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // Validation methods
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Validation methods
  bool validateForm() {
    if (completeOTP.value.length != 6) {
      Get.snackbar(
        'Validation Error',
        'Please enter complete 6-digit OTP',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    if (email.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Email not found. Please go back and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    if (validateNewPassword(newPasswordController.text) != null) {
      Get.snackbar(
        'Validation Error',
        validateNewPassword(newPasswordController.text)!,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    if (validateConfirmPassword(confirmPasswordController.text) != null) {
      Get.snackbar(
        'Validation Error',
        validateConfirmPassword(confirmPasswordController.text)!,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    return true;
  }

  // Clear OTP
  void clearOTP() {
    completeOTP.value = '';
  }

  // Clear form
  void clearForm() {
    clearOTP();
    newPasswordController.clear();
    confirmPasswordController.clear();
    isNewPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }

  // Reset password method
  Future<void> resetPassword() async {
    if (!validateForm()) {
      return;
    }

    try {
      isLoading.value = true;

      final resetPasswordRequest = ResetPasswordRequest(
        email: email.value,
        otp: completeOTP.value,
        newPassword: newPasswordController.text,
      );

      print(' SAHArSAHAr 📤 ResetPassword: Sending request for email: ${email.value}');
      final response = await _apiProvider.resetPassword(resetPasswordRequest);

      print(' SAHArSAHAr 📥 ResetPassword: Response received - Success: ${response.success}');

      if (response.success) {
        clearForm();

        Get.snackbar(
          'Success',
          response.message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        // Navigate back to Login screen
        Get.offAllNamed(AppRoutes.LOGIN_SCREEN);
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
      print(' SAHArSAHAr 💥 ResetPassword: Exception caught: $e');
      print(' SAHArSAHAr 📍 ResetPassword: Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to reset password. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Resend OTP method (if needed)
  Future<void> resendOTP() async {
    if (email.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Email not found. Please go back and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      // Clear current OTP
      clearOTP();

      print(' SAHArSAHAr 🔄 ResetPassword: Resending OTP to: ${email.value}');
      // You can call forgot password API again to resend OTP
      Get.snackbar(
        'OTP Sent',
        'New OTP has been sent to ${email.value}',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      print(' SAHArSAHAr 💥 ResetPassword: Resend error: $e');
      Get.snackbar(
        'Error',
        'Failed to resend OTP. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}