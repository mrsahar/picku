import 'package:get/get.dart';
import 'package:pick_u/models/privacy_policy_model.dart';
import 'package:pick_u/providers/api_provider.dart';

class PrivacyPolicyController extends GetxController {
  late final ApiProvider _apiProvider;

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
    try {
      _apiProvider = Get.find<ApiProvider>();
      print('PrivacyPolicyController: ApiProvider found successfully');
    } catch (e) {
      print('PrivacyPolicyController: Error finding ApiProvider: $e');
      _errorMessage.value = 'Failed to initialize: ApiProvider not found';
      return;
    }
    fetchPrivacyPolicy();
  }

  /// Fetch privacy policy from the API
  Future<void> fetchPrivacyPolicy() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      print('PrivacyPolicyController: Starting to fetch privacy policy...');

      final endpoint = '/api/Policy/get-privacy-policy';
      print('PrivacyPolicyController: Fetching from $endpoint');

      final response = await _apiProvider.postData(endpoint, {});

      print('PrivacyPolicyController: response.statusCode = ${response.statusCode}');
      print('PrivacyPolicyController: response.body = ${response.body}');

      if (response.statusCode == 200) {
        final policyResponse = PrivacyPolicyResponse.fromJson(response.body);
        _privacyPolicy.value = policyResponse;
        print('PrivacyPolicyController: Privacy policy loaded successfully');
        print('PrivacyPolicyController: Has content: ${policyResponse.hasContent}');
      } else if (response.statusCode == 401) {
        _errorMessage.value = 'Unauthorized. Please login again.';
        print('PrivacyPolicyController: 401 Unauthorized');
      } else if (response.statusCode == 404) {
        _errorMessage.value = 'Privacy policy not found.';
        print('PrivacyPolicyController: 404 Not Found');
      } else {
        _errorMessage.value = 'Failed to load privacy policy: ${response.statusText}';
        print('PrivacyPolicyController: Failed with status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _errorMessage.value = 'Error loading privacy policy: $e';
      print('PrivacyPolicyController: Exception = $e');
      print('PrivacyPolicyController: StackTrace = $stackTrace');
    } finally {
      _isLoading.value = false;
      print('PrivacyPolicyController: Loading finished. isLoading=${_isLoading.value}');
    }
  }

  /// Refresh privacy policy (pull to refresh)
  Future<void> refreshPolicy() async {
    await fetchPrivacyPolicy();
  }
}

