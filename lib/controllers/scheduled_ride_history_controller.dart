import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/services/share_pref.dart';
import 'package:pick_u/models/scheduled_ride_history_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/services/payment_service.dart';

class ScheduledRideHistoryController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Observable variables
  final _scheduledRideHistory = Rxn<ScheduledRideHistoryResponse>();
  final _isLoading = false.obs;
  final _isCancelling = false.obs;
  final _errorMessage = ''.obs;

  // Getters
  ScheduledRideHistoryResponse? get scheduledRideHistory => _scheduledRideHistory.value;
  bool get isLoading => _isLoading.value;
  bool get isCancelling => _isCancelling.value;
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
      _isCancelling.value = true;
      _errorMessage.value = '';

      // Look up the ride to get payment information
      ScheduledRideItem? ride;
      try {
        ride = rides.firstWhere((r) => r.rideId == rideId);
      } catch (e) {
        print(' SAHArSAHAr CancelRide: Ride not found in list: $e');
      }
      String? paymentIntentId = ride?.paymentIntentId;
      String? paymentStatus = ride?.paymentStatus;
      
      print(' SAHArSAHAr CancelRide: Found ride paymentIntentId = $paymentIntentId');
      print(' SAHArSAHAr CancelRide: Found ride paymentStatus = $paymentStatus');

      // Show loading dialog with animation
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false, // Prevent dismissing during cancellation
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cancelling ride...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final endpoint = '/api/Ride/cancel-ride?rideId=$rideId';
      print(' SAHArSAHAr CancelRide: API Request URL = ${_apiProvider.httpClient.baseUrl}$endpoint');

      final response = await _apiProvider.postData(endpoint, {});

      print(' SAHArSAHAr CancelRide: response.statusCode = ${response.statusCode}');
      print(' SAHArSAHAr CancelRide: response.body = ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final message = responseBody['message'] ?? 'Ride cancelled successfully';
        
        // Use payment info from ride data (API response may not include it)
        // If not found in ride, try to get from response as fallback
        paymentIntentId ??= responseBody['paymentIntentId'] as String?;
        paymentStatus ??= responseBody['paymentStatus'] as String?;
        
        print(' SAHArSAHAr CancelRide: Final paymentIntentId = $paymentIntentId');
        print(' SAHArSAHAr CancelRide: Final paymentStatus = $paymentStatus');
        
        // Release payment if it's held
        if (paymentIntentId != null && 
            paymentIntentId.isNotEmpty && 
            paymentStatus?.toLowerCase() == 'held') {
          print(' SAHArSAHAr CancelRide: Releasing held payment...');
          
          // Update dialog message
          Get.back(); // Close current dialog
          Get.dialog(
            WillPopScope(
              onWillPop: () async => false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Releasing payment...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            barrierDismissible: false,
          );
          
          final paymentReleased = await PaymentService.cancelHeldPayment(paymentIntentId);
          
          if (paymentReleased) {
            print(' SAHArSAHAr CancelRide: ✅ Payment released successfully');
          } else {
            print(' SAHArSAHAr CancelRide: ⚠️ Failed to release payment');
          }
        }
        
        // Close loading dialog
        Get.back();
        
        // Refresh the history to get updated status
        await fetchScheduledRideHistory();
        
        // Show success message with animation
        Get.snackbar(
          'Success',
          paymentIntentId != null && paymentStatus?.toLowerCase() == 'held'
              ? '$message\nPayment has been released.\n\nNote: If you do not see your held payment in available balance, it will be available in 7 working days.'
              : message,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          animationDuration: const Duration(milliseconds: 300),
        );
      } else {
        // Close loading dialog
        Get.back();
        
        final responseBody = response.body;
        final message = responseBody['message'] ?? 'Failed to cancel ride';
        _errorMessage.value = message;
        
        Get.snackbar(
          'Error',
          message,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.error, color: Colors.white),
          animationDuration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      _errorMessage.value = 'Error cancelling ride: $e';
      print(' SAHArSAHAr CancelRide: exception = $e');
      
      Get.snackbar(
        'Error',
        'Error cancelling ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
        animationDuration: const Duration(milliseconds: 300),
      );
    } finally {
      _isCancelling.value = false;
      print(' SAHArSAHAr CancelRide: loading finished');
    }
  }
}
