import 'package:get/get.dart';
import 'package:pick_u/core/sharePref.dart';
import 'package:pick_u/models/scheduled_ride_history_model.dart';
import 'package:pick_u/providers/api_provider.dart';

class ScheduledRideHistoryController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Observable variables
  final _scheduledRideHistory = Rxn<ScheduledRideHistoryResponse>();
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;

  // Getters
  ScheduledRideHistoryResponse? get scheduledRideHistory => _scheduledRideHistory.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  List<ScheduledRideItem> get rides {
    if (scheduledRideHistory?.items == null) return [];

    // Sort rides - pending latest first, then others by created date
    final sortedRides = List<ScheduledRideItem>.from(scheduledRideHistory!.items);
    sortedRides.sort((a, b) => a.compareTo(b));
    return sortedRides;
  }

  int get totalRides => rides.length;
  int get pendingRides => rides.where((ride) => ride.status.toLowerCase() == 'pending').length;
  int get completedRides => scheduledRideHistory?.completedRides ?? 0;
  double get totalFare => scheduledRideHistory?.totalFare ?? 0.0;

  // Calculate spent amount in INR
  String get totalSpentINR => '₹${totalFare.toStringAsFixed(2)}';

  @override
  void onInit() {
    super.onInit();
    fetchScheduledRideHistory();
  }

  Future<void> fetchScheduledRideHistory() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Get user ID from SharedPreferences
      final userId = await SharedPrefsService.getUserId();
      print('SAHAr ScheduledRides: userId = $userId');

      if (userId == null || userId.isEmpty) {
        _errorMessage.value = 'User ID not found. Please login again.';
        return;
      }

      final endpoint = '/api/Ride/get-user-scheduled-rides-history?userId=$userId';
      print('SAHAr ScheduledRides API Request URL = ${_apiProvider.httpClient.baseUrl}$endpoint');

      // Use POST request as per your API
      final response = await _apiProvider.postData(endpoint, {});

      print('SAHAr ScheduledRides: response.statusCode = ${response.statusCode}');
      print('SAHAr ScheduledRides: response.body = ${response.body}');

      if (response.statusCode == 200) {
        final historyResponse = ScheduledRideHistoryResponse.fromJson(response.body);
        _scheduledRideHistory.value = historyResponse;
        print('SAHAr ScheduledRides: scheduled ride history loaded successfully');
      } else {
        _errorMessage.value = 'Failed to load scheduled ride history: ${response.statusText}';
        print('SAHAr ScheduledRides: failed with statusText = ${response.statusText}');
      }
    } catch (e) {
      _errorMessage.value = 'Error loading scheduled ride history: $e';
      print('SAHAr ScheduledRides: exception = $e');
    } finally {
      _isLoading.value = false;
      print('SAHAr ScheduledRides: loading finished');
    }
  }

  Future<void> refreshHistory() async {
    await fetchScheduledRideHistory();
  }
}
