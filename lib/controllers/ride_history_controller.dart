import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/core/sharePref.dart';
import 'package:pick_u/models/ride_history_model.dart';
import 'package:pick_u/providers/api_provider.dart';

class RideHistoryController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Observable variables
  final _rideHistory = Rxn<RideHistoryResponse>();
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;

  // Getters
  RideHistoryResponse? get rideHistory => _rideHistory.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  List<RideItem> get rides => rideHistory?.items ?? [];
  int get totalRides => rides.length;
  int get completedRides => rideHistory?.completedRides ?? 0;
  int get cancelledRides => totalRides - completedRides;
  double get totalFare => rideHistory?.totalFare ?? 0.0;

  @override
  void onInit() {
    super.onInit();
    fetchRideHistory();
  }

  Future<void> fetchRideHistory() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final userId = await SharedPrefsService.getUserId();
      print('SAHAr MRSAHAr: userId = $userId');

      if (userId == null || userId.isEmpty) {
        _errorMessage.value = 'User ID not found. Please login again.';
        print('SAHAr MRSAHAr: User ID is null or empty');
        return;
      }

      final endpoint = '/api/Ride/get-user-rides-history?userId=$userId';
      print('SAHAr MRSAHAr: endpoint = $endpoint');
      print('SAHAr MRSAHAr: full URL = ${_apiProvider.httpClient.baseUrl}$endpoint');

      // Debug the headers being sent
      print('SAHAr MRSAHAr: Base URL = ${_apiProvider.httpClient.baseUrl}');
      print('SAHAr MRSAHAr: User Token = ${GlobalVariables.instance.userToken}');

      final response = await _apiProvider.postData(endpoint,{});

      print('SAHAr MRSAHAr: response.statusCode = ${response.statusCode}');
      print('SAHAr MRSAHAr: response.statusText = ${response.statusText}');
      print('SAHAr MRSAHAr: response.headers = ${response.headers}');
      print('SAHAr MRSAHAr: response.body = ${response.body}');

      if (response.statusCode == 200) {
        final historyResponse = RideHistoryResponse.fromJson(response.body);
        _rideHistory.value = historyResponse;
        print('SAHAr MRSAHAr: ride history loaded successfully');
      } else if (response.statusCode == 405) {
        // Method not allowed - check if endpoint expects POST instead of GET
        print('SAHAr MRSAHAr: 405 Method Not Allowed - API might expect POST instead of GET');
        _errorMessage.value = 'API method not allowed. Contact support.';
      } else if (response.statusCode == 401) {
        // Unauthorized
        print('SAHAr MRSAHAr: 401 Unauthorized - check token');
        _errorMessage.value = 'Unauthorized. Please login again.';
      } else {
        _errorMessage.value = 'Failed to load ride history: ${response.statusText}';
        print('SAHAr MRSAHAr: failed with statusText = ${response.statusText}');
      }
    } catch (e) {
      _errorMessage.value = 'Error loading ride history: $e';
      print('SAHAr MRSAHAr: exception = $e');
      print('SAHAr MRSAHAr: exception type = ${e.runtimeType}');
    } finally {
      _isLoading.value = false;
      print('SAHAr MRSAHAr: loading finished');
    }
  }


  Future<void> refreshHistory() async {
    await fetchRideHistory();
  }
}