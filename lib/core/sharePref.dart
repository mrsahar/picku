// sharePref.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _keyUserToken = 'user_token';
  static const String _keyTokenExpires = 'token_expires';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Save user login data
  static Future<void> saveUserData({
    required String token,
    required String expires,
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyUserToken, token);
      await prefs.setString(_keyTokenExpires, expires);
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserFullName, fullName);
      await prefs.setBool(_keyIsLoggedIn, true);

      print('SAHAr 💾 All user data saved to SharedPreferences successfully');
    } catch (e) {
      print('SAHAr 💥 Error saving to SharedPreferences: $e');
    }
  }

  // Save user login data from API response
  static Future<void> saveUserDataFromResponse(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (data['token'] != null) {
        await prefs.setString(_keyUserToken, data['token']);
      }

      if (data['expires'] != null) {
        await prefs.setString(_keyTokenExpires, data['expires']);
      }

      if (data['userId'] != null) {
        await prefs.setString(_keyUserId, data['userId']);
      }

      if (data['email'] != null) {
        await prefs.setString(_keyUserEmail, data['email']);
      }

      if (data['fullName'] != null) {
        await prefs.setString(_keyUserFullName, data['fullName']);
      }

      await prefs.setBool(_keyIsLoggedIn, true);
      print('SAHAr 💾 User data saved from API response');
    } catch (e) {
      print('SAHAr 💥 Error saving API response to SharedPreferences: $e');
    }
  }

  // Get user token
  static Future<String?> getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserToken);
    } catch (e) {
      print('SAHAr 💥 Error getting token: $e');
      return null;
    }
  }

  // Get token expiry
  static Future<String?> getTokenExpires() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyTokenExpires);
    } catch (e) {
      print('SAHAr 💥 Error getting token expiry: $e');
      return null;
    }
  }

  // Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_keyUserId);
      print('SAHAr 📱 Retrieved user ID: $userId'); // Debug log
      return userId;
    } catch (e) {
      print('SAHAr 💥 Error getting user ID: $e');
      return null;
    }
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print('SAHAr 💥 Error getting user email: $e');
      return null;
    }
  }

  // Get user full name
  static Future<String?> getUserFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserFullName);
    } catch (e) {
      print('SAHAr 💥 Error getting user full name: $e');
      return null;
    }
  }

  // Get all user data
  static Future<Map<String, String?>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'token': prefs.getString(_keyUserToken),
        'expires': prefs.getString(_keyTokenExpires),
        'userId': prefs.getString(_keyUserId),
        'email': prefs.getString(_keyUserEmail),
        'fullName': prefs.getString(_keyUserFullName),
        'isLoggedIn': prefs.getBool(_keyIsLoggedIn)?.toString(),
      };
    } catch (e) {
      print('SAHAr 💥 Error retrieving user data: $e');
      return {};
    }
  }
  // Get all user data
  static Future<Map<String, String?>> getDriverID() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'userId': prefs.getString(_keyUserId),
      };
    } catch (e) {
      print('SAHAr 💥 Error retrieving user data: $e');
      return {};
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print('SAHAr 💥 Error checking login status: $e');
      return false;
    }
  }

  // Check if token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiresStr = prefs.getString(_keyTokenExpires);

      if (expiresStr == null) return true;

      final expiryDate = DateTime.parse(expiresStr);
      final now = DateTime.now();

      return now.isAfter(expiryDate);
    } catch (e) {
      print('SAHAr 💥 Error checking token expiry: $e');
      return true; // Assume expired if there's an error
    }
  }

  // Clear all user data (for logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyUserToken);
      await prefs.remove(_keyTokenExpires);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserFullName);
      await prefs.setBool(_keyIsLoggedIn, false);

      print('SAHAr 💾 User data cleared from SharedPreferences');
    } catch (e) {
      print('SAHAr 💥 Error clearing SharedPreferences: $e');
    }
  }
}