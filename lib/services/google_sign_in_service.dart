import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

class GoogleSignInService extends GetxService {
  static GoogleSignInService get to => Get.find();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  final Rx<GoogleSignInAccount?> _currentUser = Rx<GoogleSignInAccount?>(null);
  final RxBool _isSigningIn = false.obs;

  GoogleSignInAccount? get currentUser => _currentUser.value;
  Rx<GoogleSignInAccount?> get currentUserRx => _currentUser; // Add this getter for reactive access
  bool get isSigningIn => _isSigningIn.value;
  bool get isSignedIn => _currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser.value = account;
      print(' 🔐 Google Sign-In user changed: ${account?.email ?? 'null'}');
    });

    // Check if user is already signed in
    _googleSignIn.signInSilently().then((account) {
      _currentUser.value = account;
      if (account != null) {
        print(' 🔐 User already signed in: ${account.email}');
      }
    });
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      _isSigningIn.value = true;
      print(' 🔐 Starting Google Sign-In process...');

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        _currentUser.value = account;
        print(' ✅ Google Sign-In successful: ${account.email}');

        // Get authentication details
        final GoogleSignInAuthentication googleAuth = await account.authentication;
        print(' 🔑 Access Token: ${googleAuth.accessToken != null ? 'Available' : 'null'}');
        print(' 🔑 ID Token: ${googleAuth.idToken != null ? 'Available' : 'null'}');

        return account;
      } else {
        print(' ❌ Google Sign-In was cancelled by user');
        return null;
      }
    } catch (error) {
      print(' ❌ Google Sign-In error: $error');
      Get.snackbar(
        'Sign-In Error',
        'Failed to sign in with Google. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    } finally {
      _isSigningIn.value = false;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      print(' 🔐 Signing out from Google...');
      await _googleSignIn.signOut();
      _currentUser.value = null;
      print(' ✅ Google Sign-Out successful');
    } catch (error) {
      print(' ❌ Google Sign-Out error: $error');
    }
  }

  /// Disconnect from Google (revoke access)
  Future<void> disconnect() async {
    try {
      print(' 🔐 Disconnecting from Google...');
      await _googleSignIn.disconnect();
      _currentUser.value = null;
      print(' ✅ Google disconnect successful');
    } catch (error) {
      print(' ❌ Google disconnect error: $error');
    }
  }

  /// Get user profile information
  Map<String, String?> getUserInfo() {
    final account = _currentUser.value;
    if (account == null) return {};

    return {
      'id': account.id,
      'email': account.email,
      'displayName': account.displayName,
      'photoUrl': account.photoUrl,
    };
  }

  /// Check if user is authenticated and get auth token
  Future<String?> getAuthToken() async {
    try {
      final account = _currentUser.value;
      if (account == null) return null;

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      return googleAuth.idToken;
    } catch (error) {
      print(' ❌ Error getting auth token: $error');
      return null;
    }
  }
}
