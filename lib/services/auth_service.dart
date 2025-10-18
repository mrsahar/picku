import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pick_u/services/global_variables.dart';
import 'package:pick_u/services/share_pref.dart';
import 'package:pick_u/routes/app_routes.dart';

class AuthService {
  static const String TAG = '🔐 AuthService';

  /// Check if user is authenticated and token is valid
  /// Returns true if user should stay logged in, false if should be redirected to login
  static Future<bool> isAuthenticated() async {
    try {
      print(' SAHArSAHAr $TAG: Checking authentication status...');

      // Get user data from SharedPreferences
      final userData = await SharedPrefsService.getUserData();
      final token = userData['token'];
      final expiresStr = userData['expires'];
      final isLoggedIn = userData['isLoggedIn'];

      print(' SAHArSAHAr $TAG: Token exists: ${token != null && token.isNotEmpty}');
      print(' SAHArSAHAr $TAG: Is logged in flag: $isLoggedIn');

      // Check if user has basic login data
      if (token == null || token.isEmpty || isLoggedIn != 'true') {
        print(' SAHArSAHAr $TAG: No valid login data found');
        return false;
      }

      // Check token expiry
      if (expiresStr == null || expiresStr.isEmpty) {
        print(' SAHArSAHAr $TAG: No expiry date found');
        await _clearInvalidSession();
        return false;
      }

      try {
        final expiryDate = DateTime.parse(expiresStr);
        final now = DateTime.now();
        final isExpired = now.isAfter(expiryDate);

        print(' SAHArSAHAr $TAG: Token expires at: $expiryDate');
        print(' SAHArSAHAr $TAG: Current time: $now');
        print(' SAHArSAHAr $TAG: Is expired: $isExpired');

        if (isExpired) {
          print(' SAHArSAHAr $TAG: Token expired, clearing session');
          await _clearExpiredSession();
          return false;
        }

        print(' SAHArSAHAr $TAG: Authentication valid');
        return true;

      } catch (e) {
        print(' SAHArSAHAr $TAG: Error parsing expiry date: $e');
        await _clearInvalidSession();
        return false;
      }

    } catch (e) {
      print(' SAHArSAHAr $TAG: Error checking authentication: $e');
      await _clearInvalidSession();
      return false;
    }
  }

  /// Navigate user based on authentication status
  static Future<void> checkAndNavigate() async {
    try {
      final isAuth = await isAuthenticated();

      if (isAuth) {
        print(' SAHArSAHAr $TAG: User authenticated, navigating to MainMap');

        // Update GlobalVariables for consistency
        final userData = await SharedPrefsService.getUserData();
        final globalVars = GlobalVariables.instance;
        globalVars.setUserToken(userData['token'] ?? '');
        globalVars.setUserEmail(userData['email'] ?? '');
        globalVars.setLoginStatus(true);

        // Navigate to MainMap
        Get.offAllNamed(AppRoutes.mainMap);
      } else {
        print(' SAHArSAHAr $TAG: User not authenticated, staying on login');
        Get.offAllNamed(AppRoutes.loginScreen);
      }
    } catch (e) {
      print(' SAHArSAHAr $TAG: Error in checkAndNavigate: $e');
      Get.offAllNamed(AppRoutes.loginScreen);
    }
  }

  /// Get current user data if authenticated
  static Future<Map<String, String?>?> getCurrentUser() async {
    try {
      final isAuth = await isAuthenticated();
      if (isAuth) {
        return await SharedPrefsService.getUserData();
      }
      return null;
    } catch (e) {
      print(' SAHArSAHAr $TAG: Error getting current user: $e');
      return null;
    }
  }

  /// Check if token will expire within specified minutes
  static Future<bool> willExpireSoon({int minutes = 30}) async {
    try {
      final userData = await SharedPrefsService.getUserData();
      final expiresStr = userData['expires'];

      if (expiresStr == null || expiresStr.isEmpty) return true;

      final expiryDate = DateTime.parse(expiresStr);
      final now = DateTime.now();
      final difference = expiryDate.difference(now).inMinutes;

      print(' SAHArSAHAr $TAG: Token expires in $difference minutes');
      return difference <= minutes;

    } catch (e) {
      print(' SAHArSAHAr $TAG: Error checking token expiry warning: $e');
      return true;
    }
  }

  /// Logout user and navigate to login screen
  static Future<void> logout({bool showMessage = true}) async {
    try {
      print(' SAHArSAHAr $TAG: Logging out user...');

      // Clear SharedPreferences
      await SharedPrefsService.clearUserData();

      // Clear GlobalVariables
      final globalVars = GlobalVariables.instance;
      globalVars.setLoginStatus(false);
      globalVars.setUserToken('');
      globalVars.setUserEmail('');

      if (showMessage) {
        Get.snackbar(
          'Logged Out',
          'You have been logged out successfully',
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
        );
      }

      // Navigate to login screen
      Get.offAllNamed(AppRoutes.loginScreen);

    } catch (e) {
      print(' SAHArSAHAr $TAG: Error during logout: $e');
    }
  }

  /// Private method to clear expired session
  static Future<void> _clearExpiredSession() async {
    await SharedPrefsService.clearUserData();

    // Clear GlobalVariables
    final globalVars = GlobalVariables.instance;
    globalVars.setLoginStatus(false);
    globalVars.setUserToken('');
    globalVars.setUserEmail('');

    Get.snackbar(
      'Session Expired',
      'Your session has expired. Please login again.',
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
    );
  }

  /// Private method to clear invalid session data
  static Future<void> _clearInvalidSession() async {
    await SharedPrefsService.clearUserData();

    // Clear GlobalVariables
    final globalVars = GlobalVariables.instance;
    globalVars.setLoginStatus(false);
    globalVars.setUserToken('');
    globalVars.setUserEmail('');
  }

  /// Refresh authentication status and navigate if needed
  /// Useful for calling from other screens to check session validity
  static Future<bool> refreshAuthStatus() async {
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      // Session invalid, redirect to login
      Get.offAllNamed(AppRoutes.loginScreen);
    }
    return isAuth;
  }
}


// await AuthService.checkAndNavigate();
//
// // Check auth status anywhere:
// if (await AuthService.isAuthenticated()) {
// // User is logged in with valid token
// }
//
// // Logout from anywhere:
// await AuthService.logout();