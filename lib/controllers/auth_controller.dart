import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pick_u/services/google_sign_in_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final GoogleSignInService _googleSignInService = Get.put(GoogleSignInService());

  final RxBool _isLoading = false.obs;
  final RxBool _isAuthenticated = false.obs;
  final Rx<Map<String, String?>> _userInfo = Rx<Map<String, String?>>({});

  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  Map<String, String?> get userInfo => _userInfo.value;
  bool get isGoogleSignedIn => _googleSignInService.isSignedIn;

  @override
  void onInit() {
    super.onInit();
    // Listen to Google Sign-In state changes using the public getter
    ever(_googleSignInService.currentUserRx, (GoogleSignInAccount? account) {
      _isAuthenticated.value = account != null;
      if (account != null) {
        _userInfo.value = _googleSignInService.getUserInfo();
      } else {
        _userInfo.value = {};
      }
    });
  }

  /// Handle Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;

      final GoogleSignInAccount? account = await _googleSignInService.signInWithGoogle();

      if (account != null) {
        // Google Sign-In successful
        _userInfo.value = _googleSignInService.getUserInfo();
        _isAuthenticated.value = true;

        Get.snackbar(
          'Welcome!',
          'Signed in successfully as ${account.displayName ?? account.email}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );

        // Navigate to home screen or dashboard
        // You can customize this navigation based on your app flow
        // Get.offAllNamed('/dashboard'); // Uncomment and adjust route as needed

        print(' 🎉 User authenticated: ${account.email}');
      }
    } catch (error) {
      print(' ❌ Sign-in error in controller: $error');
      Get.snackbar(
        'Error',
        'Failed to sign in. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Handle Sign Out
  Future<void> signOut() async {
    try {
      _isLoading.value = true;

      await _googleSignInService.signOut();
      _isAuthenticated.value = false;
      _userInfo.value = {};

      Get.snackbar(
        'Signed Out',
        'You have been signed out successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate back to login screen
      // Get.offAllNamed('/login'); // Uncomment and adjust route as needed

    } catch (error) {
      print(' ❌ Sign-out error in controller: $error');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get authentication token for API calls
  Future<String?> getAuthToken() async {
    return await _googleSignInService.getAuthToken();
  }
}
