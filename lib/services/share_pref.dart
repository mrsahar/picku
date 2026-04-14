// sharePref.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _keyPendingPaymentJson = 'pending_payment_state_json';

  static const String _keyUserToken = 'user_token';
  static const String _keyTokenExpires = 'token_expires';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyFcmToken = 'fcm_token';
  static const String _keyDidMigrateNotificationChannelsV4 =
      'did_migrate_notification_channels_v4';
  static const String _keyDidResetNotificationChannelsSoundV1 =
      'did_reset_notification_channels_sound_v1';
  static const String _keyNotificationChannelsSchemaVersion =
      'notification_channels_schema_version';

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

      print(' SAHArSAHAr 💾 All user data saved to SharedPreferences successfully');
    } catch (e) {
      print(' SAHArSAHAr 💥 Error saving to SharedPreferences: $e');
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
      print(' SAHArSAHAr 💾 User data saved from API response');
    } catch (e) {
      print(' SAHArSAHAr 💥 Error saving API response to SharedPreferences: $e');
    }
  }


  // Get user token
  static Future<String?> getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserToken);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error getting token: $e');
      return null;
    }
  }

  // Get token expiry
  static Future<String?> getTokenExpires() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyTokenExpires);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error getting token expiry: $e');
      return null;
    }
  }

  // Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_keyUserId);
      print(' SAHArSAHAr 📱 Retrieved user ID: $userId'); // Debug log
      return userId;
    } catch (e) {
      print(' SAHArSAHAr 💥 Error getting user ID: $e');
      return null;
    }
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error getting user email: $e');
      return null;
    }
  }

  // Get user full name
  static Future<String?> getUserFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserFullName);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error getting user full name: $e');
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
      print(' SAHArSAHAr 💥 Error retrieving user data: $e');
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
      print(' SAHArSAHAr 💥 Error retrieving user data: $e');
      return {};
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print(' SAHArSAHAr 💥 Error checking login status: $e');
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
      print(' SAHArSAHAr 💥 Error checking token expiry: $e');
      return true; // Assume expired if there's an error
    }
  }

  /// Persists in-progress payment dialog state until [clearPendingPaymentState] (successful payment / reset).
  static Future<void> savePendingPaymentState(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPendingPaymentJson, json);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error saving pending payment state: $e');
    }
  }

  static Future<String?> getPendingPaymentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyPendingPaymentJson);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error reading pending payment state: $e');
      return null;
    }
  }

  static Future<void> clearPendingPaymentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingPaymentJson);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error clearing pending payment state: $e');
    }
  }

  static Future<void> saveFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFcmToken, token);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error saving FCM token: $e');
    }
  }

  static Future<String?> getFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyFcmToken);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error getting FCM token: $e');
      return null;
    }
  }

  static Future<bool> getDidMigrateNotificationChannelsV4() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDidMigrateNotificationChannelsV4) ?? false;
    } catch (e) {
      print(' SAHArSAHAr 💥 Error reading channel migration flag: $e');
      return false;
    }
  }

  static Future<void> setDidMigrateNotificationChannelsV4(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDidMigrateNotificationChannelsV4, value);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error writing channel migration flag: $e');
    }
  }

  /// Versioned schema for Android notification channels.
  ///
  /// Android 8+ channels are sticky; to reliably apply changes (sound/importance/etc),
  /// bump the schema constant in code and migrate by deleting/recreating channels.
  static Future<int> getNotificationChannelsSchemaVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyNotificationChannelsSchemaVersion) ?? 0;
    } catch (e) {
      print(' SAHArSAHAr 💥 Error reading channel schema version: $e');
      return 0;
    }
  }

  static Future<void> setNotificationChannelsSchemaVersion(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyNotificationChannelsSchemaVersion, value);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error writing channel schema version: $e');
    }
  }

  /// One-time flag: reset Android notification channels to restore default sound.
  /// Android 8+ channels are sticky and user/device state can leave them silent.
  static Future<bool> getDidResetNotificationChannelsSoundV1() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDidResetNotificationChannelsSoundV1) ?? false;
    } catch (e) {
      print(' SAHArSAHAr 💥 Error reading channel sound reset flag: $e');
      return false;
    }
  }

  static Future<void> setDidResetNotificationChannelsSoundV1(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDidResetNotificationChannelsSoundV1, value);
    } catch (e) {
      print(' SAHArSAHAr 💥 Error writing channel sound reset flag: $e');
    }
  }

  // Clear all user data (for logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyPendingPaymentJson);
      await prefs.remove(_keyUserToken);
      await prefs.remove(_keyTokenExpires);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserFullName);
      await prefs.remove(_keyFcmToken);
      await prefs.setBool(_keyIsLoggedIn, false);

      print(' SAHArSAHAr 💾 User data cleared from SharedPreferences');
    } catch (e) {
      print(' SAHArSAHAr 💥 Error clearing SharedPreferences: $e');
    }
  }
}