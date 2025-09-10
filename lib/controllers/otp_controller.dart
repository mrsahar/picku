import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/models/otp_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/routes/app_routes.dart';

class OTPController extends GetxController {
  // Store the complete OTP
  final completeOTP = ''.obs;

  // Email from GlobalVariables (primary) or arguments (backup)
  final email = ''.obs;

  // Loading state
  final isLoading = false.obs;

  // API Provider
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  @override
  void onInit() {
    super.onInit();

    // Get email from GlobalVariables first (primary method)
    final globalVars = GlobalVariables.instance;
    if (globalVars.hasUserEmail) {
      email.value = globalVars.userEmail;
      print(' SAHArSAHAr 📧 OTP: Got email from GlobalVariables: ${email.value}');
    } else {
      // Fallback: Get email from arguments (backup method)
      final args = Get.arguments;
      if (args != null && args['email'] != null) {
        email.value = args['email'];
        print(' SAHArSAHAr 📧 OTP: Got email from arguments: ${email.value}');
      } else {
        print(' SAHArSAHAr ❌ OTP: No email found in GlobalVariables or arguments');
      }
    }
  }

  // Set complete OTP from OtpTextField
  void setCompleteOTP(String otp) {
    completeOTP.value = otp;
  }

  // Validation methods
  bool validateOTP() {
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
        'Email not found. Please go back and sign up again.',
        backgroundColor: Colors.red,
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

  // Verify OTP method
  Future<void> verifyOTP() async {
    if (!validateOTP()) {
      return;
    }

    try {
      isLoading.value = true;

      final otpRequest = OTPRequest(
        email: email.value,
        otp: completeOTP.value,
      );

      print(' SAHArSAHAr 📤 OTP: Sending verification request for: ${email.value}');
      final response = await _apiProvider.verifyOTP(otpRequest);

      if (response.success) {
        Get.snackbar(
          'Success',
          response.message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        // Navigate to Login screen (replace with your actual login screen route)
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
    } catch (e) {
      print(' SAHArSAHAr 💥 OTP: Verification error: $e');
      Get.snackbar(
        'Error',
        'Failed to verify OTP. Please try again.',
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
        'Email not found. Please go back and sign up again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      // Clear current OTP
      clearOTP();

      print(' SAHArSAHAr 🔄 OTP: Resending OTP to: ${email.value}');
      // Implement resend OTP API call here if available
      Get.snackbar(
        'OTP Sent',
        'New OTP has been sent to ${email.value}',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      print(' SAHArSAHAr 💥 OTP: Resend error: $e');
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