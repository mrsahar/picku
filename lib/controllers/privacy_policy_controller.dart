import 'package:get/get.dart';
import 'package:pick_u/models/privacy_policy_model.dart';
import 'package:pick_u/providers/api_provider.dart';

class PrivacyPolicyController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Observable variables
  final _privacyPolicy = Rxn<PrivacyPolicyResponse>();
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;

  // Getters
  PrivacyPolicyResponse? get privacyPolicy => _privacyPolicy.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get hasPolicy => _privacyPolicy.value != null;
  bool get hasContent => _privacyPolicy.value?.hasContent ?? false;

  @override
  void onInit() {
    super.onInit();
    fetchPrivacyPolicy();
  }

  /// Fetch privacy policy from the API
  Future<void> fetchPrivacyPolicy() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final endpoint = '/api/Policy/get-privacy-policy';
      print(' SAHArSAHAr MRSAHAr: Fetching privacy policy from $endpoint');

      final response = await _apiProvider.postData(endpoint, {});

      print(' SAHArSAHAr MRSAHAr: response.statusCode = ${response.statusCode}');
      print(' SAHArSAHAr MRSAHAr: response.body = ${response.body}');

      if (response.statusCode == 200) {
        final policyResponse = PrivacyPolicyResponse.fromJson(response.body);
        _privacyPolicy.value = policyResponse;
        print(' SAHArSAHAr MRSAHAr: Privacy policy loaded successfully');
      } else if (response.statusCode == 401) {
        _errorMessage.value = 'Unauthorized. Please login again.';
        print(' SAHArSAHAr MRSAHAr: 401 Unauthorized');
      } else if (response.statusCode == 404) {
        _errorMessage.value = 'Privacy policy not found.';
        print(' SAHArSAHAr MRSAHAr: 404 Not Found');
      } else {
        _errorMessage.value = 'Failed to load privacy policy: ${response.statusText}';
        print(' SAHArSAHAr MRSAHAr: Failed with status ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage.value = 'Error loading privacy policy: $e';
      print(' SAHArSAHAr MRSAHAr: Exception = $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh privacy policy (pull to refresh)
  Future<void> refreshPolicy() async {
    await fetchPrivacyPolicy();
  }
}

