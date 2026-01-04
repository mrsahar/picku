import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/services/share_pref.dart';
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
  String get totalSpentINR => '\$${totalFare.toStringAsFixed(2)}';

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
      print(' SAHArSAHAr ScheduledRides: userId = $userId');

      if (userId == null || userId.isEmpty) {
        _errorMessage.value = 'User ID not found. Please login again.';
        return;
      }

      final endpoint = '/api/Ride/get-user-scheduled-rides-history?userId=$userId';
      print(' SAHArSAHAr ScheduledRides API Request URL = ${_apiProvider.httpClient.baseUrl}$endpoint');

      // Use POST request as per your API
      final response = await _apiProvider.postData(endpoint, {});

      print(' SAHArSAHAr ScheduledRides: response.statusCode = ${response.statusCode}');
      print(' SAHArSAHAr ScheduledRides: response.body = ${response.body}');

      if (response.statusCode == 200) {
        // Debug: Print the raw response to see all available fields
        print(' SAHArSAHAr ScheduledRides: Raw response body = ${response.body}');
        if (response.body is Map && response.body['items'] != null) {
          final items = response.body['items'] as List;
          if (items.isNotEmpty) {
            print(' SAHArSAHAr ScheduledRides: First item keys = ${items[0].keys}');
            print(' SAHArSAHAr ScheduledRides: First item = ${items[0]}');
          }
        }
        
        final historyResponse = ScheduledRideHistoryResponse.fromJson(response.body);
        _scheduledRideHistory.value = historyResponse;
        print(' SAHArSAHAr ScheduledRides: scheduled ride history loaded successfully');
      } else {
        _errorMessage.value = 'Failed to load scheduled ride history: ${response.statusText}';
        print(' SAHArSAHAr ScheduledRides: failed with statusText = ${response.statusText}');
      }
    } catch (e) {
      _errorMessage.value = 'Error loading scheduled ride history: $e';
      print(' SAHArSAHAr ScheduledRides: exception = $e');
    } finally {
      _isLoading.value = false;
      print(' SAHArSAHAr ScheduledRides: loading finished');
    }
  }

  Future<void> refreshHistory() async {
    await fetchScheduledRideHistory();
  }

  Future<void> cancelRide(String rideId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final endpoint = '/api/Ride/cancel-ride?rideId=$rideId';
      print(' SAHArSAHAr CancelRide: API Request URL = ${_apiProvider.httpClient.baseUrl}$endpoint');

      final response = await _apiProvider.postData(endpoint,{});

      print(' SAHArSAHAr CancelRide: response.statusCode = ${response.statusCode}');
      print(' SAHArSAHAr CancelRide: response.body = ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final message = responseBody['message'] ?? 'Ride cancelled successfully';
        
        // Refresh the history to get updated status
        await fetchScheduledRideHistory();
        
        Get.snackbar(
          'Success',
          message,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        final responseBody = response.body;
        final message = responseBody['message'] ?? 'Failed to cancel ride';
        _errorMessage.value = message;
        
        Get.snackbar(
          'Error',
          message,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      _errorMessage.value = 'Error cancelling ride: $e';
      print(' SAHArSAHAr CancelRide: exception = $e');
      
      Get.snackbar(
        'Error',
        'Error cancelling ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
      print(' SAHArSAHAr CancelRide: loading finished');
    }
  }
}
