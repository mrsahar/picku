// controllers/signup_controller.dart (No GlobalKey approach)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/providers/api_provider.dart';
import '../models/signup_model.dart';
import '../routes/app_routes.dart';

class SignUpController extends GetxController {
  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Local loading state
  final isLoading = false.obs;

  // Validation error states - YE NAI ADD KIYE HAIN
  final fullNameError = ''.obs;
  final emailError = ''.obs;
  final phoneError = ''.obs;
  final passwordError = ''.obs;

  // API Provider
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Validation methods
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
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

  // Manual validation without GlobalKey
  bool validateForm() {
    return validateFullName(fullNameController.text) == null &&
        validateEmail(emailController.text) == null &&
        validatePhone(phoneController.text) == null &&
        validatePassword(passwordController.text) == null;
  }

  // YE NAI METHODS HAIN - Individual field validation with error setting
  void validateAndSetFullNameError() {
    final error = validateFullName(fullNameController.text);
    fullNameError.value = error ?? '';
  }

  void validateAndSetEmailError() {
    final error = validateEmail(emailController.text);
    emailError.value = error ?? '';
  }

  void validateAndSetPhoneError() {
    final error = validatePhone(phoneController.text);
    phoneError.value = error ?? '';
  }

  void validateAndSetPasswordError() {
    final error = validatePassword(passwordController.text);
    passwordError.value = error ?? '';
  }

  // YE NAI METHODS HAIN - Clear individual errors
  void clearFullNameError() => fullNameError.value = '';
  void clearEmailError() => emailError.value = '';
  void clearPhoneError() => phoneError.value = '';
  void clearPasswordError() => passwordError.value = '';

  // YE NAI METHOD HAI - Clear all errors
  void clearAllErrors() {
    fullNameError.value = '';
    emailError.value = '';
    phoneError.value = '';
    passwordError.value = '';
  }

  // YE NAI METHOD HAI - Validate all fields and set errors
  bool validateFormWithErrors() {
    // Clear previous errors
    clearAllErrors();

    // Validate each field and set errors
    validateAndSetFullNameError();
    validateAndSetEmailError();
    validateAndSetPhoneError();
    validateAndSetPasswordError();

    // Return true if no errors
    return fullNameError.value.isEmpty &&
        emailError.value.isEmpty &&
        phoneError.value.isEmpty &&
        passwordError.value.isEmpty;
  }


  Future<void> signUp() async {
    // Manual validation with error display
    if (!validateFormWithErrors()) {
      Get.snackbar(
        'Validation Error',
        'Please fill all fields correctly',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      isLoading.value = true;

      final signUpRequest = SignUpRequest(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );

      final response = await _apiProvider.signUp(signUpRequest);

      if (response.success) {
        // Save email in GlobalVariables for later use
        final globalVars = GlobalVariables.instance;
        globalVars.setUserEmail(emailController.text.trim());
        _clearForm();

        Get.snackbar(
          'Success',
          response.message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        // Navigate to OTP screen with email parameter (backup method)
        Get.toNamed(AppRoutes.OTP_SCREEN, arguments: {
          'email': emailController.text.trim(),
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
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create account. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }


  void _clearForm() {
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    clearAllErrors();
  }
}