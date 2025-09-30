// lib/app/services/constants/app_constants.dart
class AppConstants {
  static const String API_BASE_URL = 'http://pickurides.com';

  // API Endpoints
  static const String USERS_ENDPOINT = '/users';
  static const String POSTS_ENDPOINT = '/posts';

  // Storage Keys
  static const String USER_TOKEN_KEY = 'user_token';
  static const String IS_LOGGED_IN_KEY = 'is_logged_in';

  // Error Messages
  static const String NETWORK_ERROR = 'Network error occurred';
  static const String SERVER_ERROR = 'Server error occurred';
  static const String UNKNOWN_ERROR = 'Unknown error occurred';
}