import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/core/sharePref.dart';
import 'package:pick_u/models/login_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/routes/app_routes.dart';

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

    checkAuthenticationStatus();
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
    return "deviceToken_placeholder_${DateTime.now().millisecondsSinceEpoch}";
  }

  // Updated Login method with SharedPrefsService integration
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
        deviceToken:'',
      );

      print('SAHAr 📤 Login: Sending request for email: ${emailController.text}');
      final response = await _apiProvider.login(loginRequest);

      if (response.success && response.data != null) {
        // Check if the message is "Login successful"
        final message = response.data['message'] ?? response.message;

        if (message == "Login successful") {
          // Save user data to SharedPreferences
          await SharedPrefsService.saveUserDataFromResponse(response.data);

          // Also save to GlobalVariables for backward compatibility
          final globalVars = GlobalVariables.instance;
          globalVars.setUserEmail(response.data['email'] ?? emailController.text.trim());
          globalVars.setLoginStatus(true);
          globalVars.setUserToken(response.data['token']);

          // Clear form on success
          clearForm();

          // Show success message
          Get.snackbar(
            'Success',
            message,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );

          // Navigate to MainMap
          Get.offAllNamed(AppRoutes.MainMap);
        } else {
          // Show the message from API response
          Get.snackbar(
            'Error',
            message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        // Handle API error response
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('SAHAr 💥 Login: Error: $e');
      Get.snackbar(
        'Error',
        'Failed to login. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Enhanced method to check authentication status with token validation
  Future<void> checkAuthenticationStatus() async {
    try {
      print('SAHAr 🔍 Checking authentication status...');

      // Get user data from SharedPreferences
      final userData = await SharedPrefsService.getUserData();
      final token = userData['token'];
      final expiresStr = userData['expires'];
      final isLoggedIn = userData['isLoggedIn'];

      print('SAHAr 📱 Token exists: ${token != null}');
      print('SAHAr 📱 Is logged in: $isLoggedIn');
      print('SAHAr 📱 Expires: $expiresStr');

      // Check if user has login data
      if (token != null && token.isNotEmpty && isLoggedIn == 'true') {
        print('SAHAr ✅ User has login data, checking token expiry...');

        // Check if token is expired
        final isTokenExpired = await SharedPrefsService.isTokenExpired();
        final now = DateTime.now();

        if (expiresStr != null) {
          try {
            final expiryDate = DateTime.parse(expiresStr);
            print('SAHAr ⏰ Token expires at: $expiryDate');
            print('SAHAr ⏰ Current time: $now');
            print('SAHAr ⏰ Token expired: $isTokenExpired');

            if (!isTokenExpired && now.isBefore(expiryDate)) {
              // Token is valid, navigate to MainMap
              print('SAHAr 🚀 Token is valid, navigating to MainMap');

              // Update GlobalVariables for consistency
              final globalVars = GlobalVariables.instance;
              globalVars.setUserToken(token);
              globalVars.setUserEmail(userData['email'] ?? '');
              globalVars.setLoginStatus(true);

              // Navigate to MainMap
              Get.offAllNamed(AppRoutes.MainMap);
              return;
            }
          } catch (e) {
            print('SAHAr 💥 Error parsing expiry date: $e');
          }
        }

        // Token is expired or invalid
        print('SAHAr ❌ Token expired or invalid, clearing data and staying on login');
        await SharedPrefsService.clearUserData();

        // Clear GlobalVariables
        final globalVars = GlobalVariables.instance;
        globalVars.setLoginStatus(false);
        globalVars.setUserToken('');
        globalVars.setUserEmail('');

        // Show session expired message
        Get.snackbar(
          'Session Expired',
          'Your session has expired. Please login again.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      } else {
        print('SAHAr ❌ No valid login data found, staying on login screen');
      }
    } catch (e) {
      print('SAHAr 💥 Error checking authentication status: $e');
      // On error, clear any corrupted data and stay on login screen
      await SharedPrefsService.clearUserData();
    }
  }

  // Method to manually check login status (for backward compatibility)
  Future<void> checkLoginStatus() async {
    await checkAuthenticationStatus();
  }

  // Method to logout user
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Clear SharedPreferences
      await SharedPrefsService.clearUserData();

      // Clear GlobalVariables
      final globalVars = GlobalVariables.instance;
      globalVars.setLoginStatus(false);
      globalVars.setUserToken('');
      globalVars.setUserEmail('');

      // Clear form
      clearForm();

      // Navigate to login screen
      Get.offAllNamed(AppRoutes.LOGIN_SCREEN);

      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      print('SAHAr 💥 Logout error: $e');
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