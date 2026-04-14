import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/services/google_places_service.dart';
import 'package:pick_u/services/location_service.dart';
import 'package:pick_u/services/map_service.dart';
import 'package:pick_u/services/payment_service.dart';
import 'package:pick_u/services/search_location_service.dart';
import 'package:pick_u/services/share_pref.dart';
import 'package:pick_u/services/signalr_service.dart';
import 'package:pick_u/services/chat_background_service.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:pick_u/dialogs/thank_you_dialog.dart';

// Constants
class ApiEndpoints {
  static const String bookRide = '/api/Ride/book';
  static const String startTrip = '/api/Ride/{rideId}/start';
  static const String endTrip = '/api/Ride/{rideId}/end';
  static const String submitTip = '/api/Tip';
  static const String processPayment = '/api/Payment/customer-payments';
  static const String fareEstimate = '/api/Ride/fare-estimate';
  static const String submitFeedback = '/api/Feedback';
  static const String saveHeldPayment = '/api/Payment/held-payments';
  static const String completeTransaction = '/api/Payment/complete-transaction';
  static const String cancelRide = '/api/Payment/cancel-ride';
  static const String verifyPromo = '/api/user/verify-promo';
  /// POST `?userId=` — latest ride for resume / held-payment recovery (see [RideBookingController.checkLastRideOnHomeOpen]).
  static const String getUserLastRide = '/api/Ride/get-user-last-ride';
  /// POST — passenger app can load Stripe Connect id when missing (same as [DriverDto.StripeAccountId]).
  static String getDriverById(String driverId) => '/api/Drivers/$driverId';
}

class AppConstants {
  static const String defaultUserId = "44f9ebba-b24d-4df1-8a60-bd7035b6097d";
  static const List<double> tipPercentages = [10.0, 15.0, 20.0];
  static const String defaultUserName = "Name";
}

// Enum for ride status
enum RideStatus {
  pending,
  booked,
  waiting,
  driverAssigned,
  driverNear,
  driverArrived,
  tripStarted,
  tripCompleted,
  cancelled,
  noDriver
}

/// Post–trip-end UI after capturing fare (see [_completePayment]).
enum RidePaymentCompletionStyle {
  /// Success banner + review (default; SignalR / in-app trip completion).
  standard,
  /// Capture fare without the full payment sheet; then optional tip + review
  /// (FCM when SignalR is down, or resumed completed ride with held auth).
  autoFareThenOptionalTip,
}

class RideBookingController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Inject services
  final LocationService _locationService = Get.find<LocationService>();
  final SearchService _searchService = Get.find<SearchService>();
  final MapService _mapService = Get.find<MapService>();

  // Audio player for **in-app** alerts only (NOT OS notifications).
  final AudioPlayer _inAppAlertPlayer = AudioPlayer();

  // Text Controllers
  final pickupController = TextEditingController();
  final dropoffController = TextEditingController();
  var stopControllers = <TextEditingController>[].obs;

  // Reactive text values for UI updates
  var pickupText = ''.obs;
  var dropoffText = ''.obs;

  // Core ride data
  var pickupLocation = Rx<LocationData?>(null);
  var dropoffLocation = Rx<LocationData?>(null);
  var additionalStops = <LocationData>[].obs;
  var passengerCount = 1.obs;
  var rideType = 'standard'.obs;
  var isMultiStopRide = false.obs;

  // Scheduling variables
  // Fare estimation variables
  var estimatedFare = 0.0.obs;
  var fareSubtotal = 0.0.obs;
  var fareDiscount = 0.0.obs;
  /// True when last fare-estimate used the flat `total` / `subtotal` / `discount` shape.
  var fareBreakdownAvailable = false.obs;
  var fareMessage = ''.obs;
  var fareCurrency = 'CAD'.obs;
  var adminPercentage = 0.0.obs; // Admin share percentage from fare API
  var isLoadingFare = false.obs;

  final promoCodeController = TextEditingController();
  var appliedPromoCode = ''.obs;
  /// From verify-promo; required by fare-estimate POST body for server-side discount.
  var appliedPromoCodeId = ''.obs;
  var appliedPromoFlatAmount = 0.0.obs;
  var appliedPromoMinFare = 0.0.obs;
  var promoError = ''.obs;
  var isVerifyingPromo = false.obs;
  bool _hasShownServiceUnavailable = false; // Prevent duplicate snackbars

  var isScheduled = false.obs;
  var scheduledDate = Rx<DateTime?>(null);
  var scheduledTime = Rx<TimeOfDay?>(null);

  // Ride booking state
  var isLoading = false.obs;
  var isRideBooked = false.obs;
  var currentRideId = ''.obs;
  var prevRideId = ''.obs;
  var rideStatus = RideStatus.pending.obs; // Using enum now

  // Driver information
  var driverId = ''.obs;
  var driverName = ''.obs;
  var driverPhone = ''.obs;
  var estimatedPrice = 0.0.obs;
  var actualFareBeforeBalance = 0.0.obs; // Store actual fare before balance deduction
  var vehicle = ''.obs;
  var vehicleColor = ''.obs;
  var rating = 0.0.obs;
  var driverStripeAccountId = ''.obs; // Driver's Stripe Connected Account ID

  // Driver location tracking
  final driverLatitude = 0.0.obs;
  final driverLongitude = 0.0.obs;
  final isDriverLocationActive = false.obs;

  // Store payment intent ID when ride is booked
  RxString heldPaymentIntentId = ''.obs;

  /// Ensures we only run last-ride resume / held-payment logic once per app session.
  bool _lastRideResumeCheckDone = false;
  /// Monotonic token to ignore stale async last-ride responses after navigation.
  int _lastRideResumeCheckSeq = 0;
  // Store the amount that was held for payment
  double _heldAmount = 0.0;
  // Store selected tip amount
  var selectedTipAmount = 0.0.obs;
  // Store payment dialog data for re-opening
  Map<String, dynamic>? _paymentDialogData;
  /// Set after a successful fare capture so FCM / API duplicate "complete" events are ignored.
  String _fareCaptureCompletedRideId = '';
  // Ride duration display for payment popup
  var rideDurationDisplay = 'Calculating...'.obs;

  // Distance tracking for destination (when trip started)
  final distanceToDestination = 0.0.obs;
  final isTrackingDestination = false.obs;

  // Distance-based notifications
  final hasShownApproachingNotification = false.obs;
  final hasShownArrivedNotification = false.obs;

  // Local ride duration tracking
  var localRideStartTime = Rx<DateTime?>(null);
  var localRideEndTime = Rx<DateTime?>(null);

  // SignalR Service
  late SignalRService signalRService;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _setupLocationListener();
    _setupTextControllerListeners();
  }

  void _setupTextControllerListeners() {
    // Listen to pickup text controller changes
    pickupController.addListener(() {
      pickupText.value = pickupController.text;
    });

    // Listen to dropoff text controller changes
    dropoffController.addListener(() {
      dropoffText.value = dropoffController.text;
    });
  }

  Future<void> _initializeServices() async {
    signalRService = Get.find<SignalRService>();
  }

  void _setupLocationListener() {
    // Listen to user location changes to update distance to destination when trip is started
    ever(_locationService.currentLatLng, (LatLng? newLocation) {
      if (newLocation != null && isTrackingDestination.value) {
        _updateDistanceToDestination();
      }
    });
  }

  void _updateDistanceToDestination() {
    if (dropoffLocation.value != null && _locationService.currentLatLng.value != null) {
      LatLng userLocation = _locationService.currentLatLng.value!;
      LatLng destinationLocation = LatLng(
        dropoffLocation.value!.latitude,
        dropoffLocation.value!.longitude,
      );

      double distance = _locationService.calculateDistance(userLocation, destinationLocation);
      distanceToDestination.value = distance;

      print(' SAHAr Distance to destination updated: ${distance.round()}m');
    }
  }

  @override
  void onClose() {
    pickupController.dispose();
    dropoffController.dispose();
    promoCodeController.dispose();
    for (var controller in stopControllers) {
      controller.dispose();
    }
    super.onClose();
  }

  double _parseFareNumber(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double _roundMoney2(double x) => (x * 100).round() / 100;

  /// When backend **fareEstimate** and **fareFinal** match what the user saw, but the
  /// persisted [_heldAmount] is slightly lower (rounding / save drift), align the hold to
  /// the final fare so we do not show a misleading "Pay \$0.10" on an \$8.90 trip.
  void _reconcileHeldAmountWhenQuoteMatchesFinal(
    double finalFare,
    double quotedFare, {
    double quoteMatchEps = 0.06,
    double maxShortfall = 0.30,
  }) {
    if (finalFare <= 0 || quotedFare <= 0 || _heldAmount <= 0) return;
    final f = _roundMoney2(finalFare);
    final q = _roundMoney2(quotedFare);
    if ((q - f).abs() > quoteMatchEps) return;
    final held = _roundMoney2(_heldAmount);
    final shortfall = f - held;
    if (shortfall > 0 && shortfall <= maxShortfall) {
      print(
          'SAHAr: held amount reconciled \$${held.toStringAsFixed(2)} → \$${f.toStringAsFixed(2)} '
          '(quoted \$${q.toStringAsFixed(2)} matches final \$${f.toStringAsFixed(2)})');
      _heldAmount = f;
      if (estimatedPrice.value + 0.001 < _heldAmount) {
        estimatedPrice.value = _heldAmount;
      }
    }
  }

  String _formatPromoMoney(double amount) {
    final c = fareCurrency.value;
    if (c == 'CAD' || c == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '$c ${amount.toStringAsFixed(2)}';
  }

  /// When fare-estimate still returns discount 0, apply verify-promo [flatAmount] locally.
  ///
  /// [minFare] from verify-promo is treated as the **minimum pre-discount ride total** required
  /// for the promo to apply — not a floor on the price after discount (which incorrectly capped
  /// discounts and could inflate cheap rides up to [minFare]).
  void _syncFareWithVerifiedFlatPromoIfNeeded() {
    if (appliedPromoCode.value.isEmpty || appliedPromoFlatAmount.value <= 0) {
      return;
    }
    if (fareDiscount.value > 0) return;

    final double base = (fareBreakdownAvailable.value && fareSubtotal.value > 0)
        ? fareSubtotal.value
        : estimatedFare.value;
    if (base <= 0) return;

    final minF = appliedPromoMinFare.value;
    if (minF > 0 && base < minF) {
      fareBreakdownAvailable.value = true;
      fareSubtotal.value = base;
      fareDiscount.value = 0.0;
      estimatedFare.value = base;
      promoError.value =
          'This promo needs a ride total of at least ${_formatPromoMoney(minF)} (before discount)';
      return;
    }

    promoError.value = '';
    final double discount =
        appliedPromoFlatAmount.value.clamp(0.0, base);
    final double total = base - discount;

    fareBreakdownAvailable.value = true;
    fareSubtotal.value = base;
    fareDiscount.value = discount;
    estimatedFare.value = total;
  }

  void _clearAppliedPromo() {
    appliedPromoCode.value = '';
    appliedPromoCodeId.value = '';
    appliedPromoFlatAmount.value = 0.0;
    appliedPromoMinFare.value = 0.0;
  }

  /// Verifies promo via API; clears promo when input is empty. Refreshes fare on success or clear.
  ///
  /// verify-promo returns `code`, `promoCodeId`, `flatAmount`, `minFare` (min **pre-discount**
  /// ride total to qualify), `isActive`.
  /// fare-estimate expects `promoCodeId` + `distance` in the POST body.
  Future<void> verifyPromoCode() async {
    final raw = promoCodeController.text.trim();
    promoError.value = '';

    if (raw.isEmpty) {
      _clearAppliedPromo();
      await getFareEstimate();
      Get.snackbar('Promo', 'Promo code removed');
      return;
    }

    isVerifyingPromo.value = true;
    try {
      final response =
          await _apiProvider.postData(ApiEndpoints.verifyPromo, {'promoCode': raw});
      final body = response.body;

      if (!response.isOk) {
        final msg = body is Map<String, dynamic>
            ? (body['message']?.toString() ??
                body['error']?.toString() ??
                response.statusText)
            : response.statusText;
        promoError.value = msg ?? 'Could not verify promo code';
        Get.snackbar('Promo', promoError.value);
        return;
      }

      if (body is! Map<String, dynamic>) {
        promoError.value = 'Invalid response';
        Get.snackbar('Promo', promoError.value);
        return;
      }

      if (body['isActive'] == false) {
        promoError.value = 'This promo code is no longer active';
        _clearAppliedPromo();
        await getFareEstimate();
        Get.snackbar('Promo', promoError.value);
        return;
      }

      final code = body['code']?.toString().trim() ?? '';
      final returnedLegacy = body['promoCode']?.toString().trim() ?? '';
      final promoCodeId = body['promoCodeId']?.toString().trim() ?? '';
      final valid = body['valid'] == true ||
          body['isValid'] == true ||
          body['success'] == true;

      final accepted = valid ||
          promoCodeId.isNotEmpty ||
          code.isNotEmpty ||
          returnedLegacy.isNotEmpty;

      if (accepted) {
        appliedPromoCode.value = code.isNotEmpty
            ? code
            : (returnedLegacy.isNotEmpty ? returnedLegacy : raw);
        appliedPromoCodeId.value = promoCodeId;
        appliedPromoFlatAmount.value = _parseFareNumber(body['flatAmount']);
        appliedPromoMinFare.value = _parseFareNumber(body['minFare']);

        await getFareEstimate();
        // Discount sync runs inside getFareEstimate after Rx updates (post-frame).

        final off = appliedPromoFlatAmount.value;
        final label = appliedPromoCode.value;
        final minF = appliedPromoMinFare.value;
        final subtitle = off > 0
            ? '${_formatPromoMoney(off)} off'
                '${minF > 0 ? ' · ride ≥ ${_formatPromoMoney(minF)} before discount' : ''}'
            : 'Applied to your estimate';
        Get.snackbar(
          'Promo applied',
          '$label · $subtitle',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        );
      } else {
        final msg = body['message']?.toString().trim() ?? '';
        promoError.value =
            msg.isNotEmpty ? msg : 'Invalid or expired promo code';
        _clearAppliedPromo();
        await getFareEstimate();
        Get.snackbar('Promo', promoError.value);
      }
    } finally {
      isVerifyingPromo.value = false;
    }
  }

  // Update driver location from SignalR
  void updateDriverLocation(double latitude, double longitude) {
    driverLatitude.value = latitude;
    driverLongitude.value = longitude;
    isDriverLocationActive.value = true;

    print(' SAHArSAHAr Controller: Driver location updated: ($latitude, $longitude)');
    _checkDriverDistanceAndNotify();

    // Trigger map animation through MapService
    String driverDisplayName = driverName.value.isNotEmpty ? driverName.value : 'Driver';
    _mapService.updateDriverMarkerWithAnimation(
      latitude,
      longitude,
      driverDisplayName,
      centerMap: true,
    );
  }

  // Check driver distance and show appropriate notifications
  void _checkDriverDistanceAndNotify() {
    double? distance = getDistanceToDriver();

    // Debug logging
    print('SAHAr Distance Check - Distance: $distance, RideStatus: ${rideStatus.value}');
    print('SAHAr Notification flags - Approaching: ${hasShownApproachingNotification.value}, Arrived: ${hasShownArrivedNotification.value}');

    // Return early if no distance or inappropriate ride status
    if (distance == null) {
      print('SAHAr Distance Check: No distance available');
      return;
    }

    // Only show notifications for these ride statuses
    if (rideStatus.value != RideStatus.driverAssigned &&
        rideStatus.value != RideStatus.driverNear &&
        rideStatus.value != RideStatus.driverArrived &&
        rideStatus.value != RideStatus.waiting &&
        rideStatus.value != RideStatus.booked) {
      print('SAHAr Distance Check: Wrong ride status (${rideStatus.value}) for notifications');
      return;
    }

    print('SAHAr Driver distance: ${distance.round()}m');

    // Show "Driver has arrived" notification (10m or less)
    if (distance <= 10 && !hasShownArrivedNotification.value) {
      print('SAHAr Showing arrived dialog - Distance: ${distance.round()}m');
      hasShownArrivedNotification.value = true;
      rideStatus.value = RideStatus.driverArrived; // Update ride status
      _showDriverArrivedDialog();
      _playInAppAlertSound(); // In-app custom sound
    }
    // Show "Driver is approaching" notification (75m or less, but more than 10m)
    else if (distance <= 75 && distance > 10 && !hasShownApproachingNotification.value) {
      print('SAHAr Showing approaching dialog - Distance: ${distance.round()}m');
      hasShownApproachingNotification.value = true;
      rideStatus.value = RideStatus.driverNear; // Update ride status
      _showDriverApproachingDialog();
      _playInAppAlertSound(); // In-app custom sound
    }
  }

  /// In-app alert sound + vibration. This does NOT affect system notifications.
  Future<void> _playInAppAlertSound() async {
    try {
      await _inAppAlertPlayer.stop();
      await _inAppAlertPlayer.play(AssetSource('sounds/notification.mp3'), volume: 1.0);
    } catch (e) {
      print('SAHAr Error playing in-app alert sound: $e');
    } finally {
      _startVibration();
    }
  }

  Future<void> _startVibration() async {
    try {
      for (int i = 0; i < 6; i++) {
        HapticFeedback.heavyImpact(); // Strong vibration
        await Future.delayed(const Duration(milliseconds: 500));
      }
      print('SAHAr Vibration pattern completed (3 seconds)');
    } catch (e) {
      print('SAHAr Error starting vibration: $e');
    }
  }

  // Show driver approaching notification (75m or less)
  void _showDriverApproachingDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              Icons.directions_car_rounded,
              size: 56,
              color: MColor.primaryNavy,
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Driver Approaching!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MColor.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              '${driverName.value.isNotEmpty ? driverName.value : "Your driver"} is getting close to your pickup location.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Please be ready!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Expected arrival info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: MColor.primaryNavy),
                const SizedBox(width: 6),
                Text(
                  'Expected arrival: ${getFormattedDistanceToDriver()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColor.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () => Get.back(),
              child: const Text(
                'Got it!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    // Auto-dismiss after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    });
  }


  /// Call this when driver arrived status is received from SignalR (or elsewhere).
  /// Shows the same "Driver Has Arrived!" dialog and prevents duplicate show from distance logic.
  void showDriverArrivedDialogFromSignalR() {
    if (hasShownArrivedNotification.value) return;
    hasShownArrivedNotification.value = true;
    _playInAppAlertSound(); // In-app custom sound
    _showDriverArrivedDialog();
  }

  /// Call when ride status Cancelled is received from SignalR.
  /// Runs: complete payment (or release hold) → show review popup → user dismisses review triggers reset via clearBooking.
  Future<void> handleRideCancelledFromSignalR() async {
    try {
      double finalFare = actualFareBeforeBalance.value > 0
          ? actualFareBeforeBalance.value
          : 0.0;
      double tip = selectedTipAmount.value;
      await _completePayment(finalFare, tipAmount: tip);
      // _completePayment shows review dialog; Skip/Submit in review call clearBooking()
    } catch (e) {
      print('SAHAr: handleRideCancelledFromSignalR payment error: $e');
      // Still show review and reset so user is not stuck
      clearPaymentData();
      _showReviewDialog();
    }
  }

  // Show driver arrived notification (10m or less)
  void _showDriverArrivedDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: MColor.primaryNavy,
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Driver Has Arrived!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MColor.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              '${driverName.value.isNotEmpty ? driverName.value : "Your driver"} is here and ready to start your ride.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColor.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Get.back(),
              child: const Text('Got It'),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  LatLng? getDriverLocation() {
    if (driverLatitude.value != 0.0 && driverLongitude.value != 0.0) {
      return LatLng(driverLatitude.value, driverLongitude.value);
    }
    return null;
  }
  double? getDistanceToDriver() {
    LatLng? userLocation = _locationService.currentLatLng.value;
    LatLng? driverLocation = getDriverLocation();

    if (userLocation != null && driverLocation != null) {
      return _locationService.calculateDistance(userLocation, driverLocation);
    }

    return null;
  }

// Get formatted distance to driver
  String getFormattedDistanceToDriver() {
    // When trip has started, show distance to destination instead of driver
    if (rideStatus.value == RideStatus.tripStarted && isTrackingDestination.value) {
      if (distanceToDestination.value > 0) {
        double distance = distanceToDestination.value;
        if (distance < 1000) {
          return '${distance.round()}m remaining';
        } else {
          return '${(distance / 1000).toStringAsFixed(1)} km remaining';
        }
      } else {
        return 'Calculating distance...';
      }
    }

    // Default behavior - show distance to driver
    double? distance = getDistanceToDriver();
    if (distance != null) {
      if (distance < 1000) {
        return '${distance.round()}m away';
      } else {
        return '${(distance / 1000).toStringAsFixed(1)}km away';
      }
    }
    return 'Distance unknown';
  }

// Clear driver location when ride ends
  void clearDriverLocation() {
    driverLatitude.value = 0.0;
    driverLongitude.value = 0.0;
    isDriverLocationActive.value = false;

    // Reset notification flags when clearing driver location
    hasShownApproachingNotification.value = false;
    hasShownArrivedNotification.value = false;
  }

  // FIXED: Multi-stop management - using proper observable updates
  void addStop() {
    final controller = TextEditingController();
    stopControllers.add(controller);

    additionalStops.add(LocationData(
      address: '',
      latitude: 0,
      longitude: 0,
      stopOrder: additionalStops.length + 1,
    ));

    // Force UI update
    stopControllers.refresh();
    additionalStops.refresh();
    print(' SAHArSAHAr Stop added. Total stops: ${additionalStops.length}');
  }

  Future<void> removeStop(int index) async {
    if (index >= 0 && index < stopControllers.length) {
      stopControllers[index].dispose();
      stopControllers.removeAt(index);

      if (index < additionalStops.length) {
        additionalStops.removeAt(index);
      }

      // 1. Re-index remaining stops taake sequence sahi rahe
      for (int i = 0; i < additionalStops.length; i++) {
        final oldStop = additionalStops[i];
        additionalStops[i] = LocationData(
          address: oldStop.address,
          latitude: oldStop.latitude,
          longitude: oldStop.longitude,
          stopOrder: i + 1, // Pickup (0), Stops (1..N), Dropoff (N+1)
        );
      }

      stopControllers.refresh();
      additionalStops.refresh();

      // 2. RE-CALCULATE Everything automatically
      if (pickupLocation.value != null && dropoffLocation.value != null) {
        // Map par polylines aur markers update karein
        await _mapService.createRouteMarkersAndPolylines(
          pickupLocation: pickupLocation.value,
          dropoffLocation: dropoffLocation.value,
          additionalStops: additionalStops,
        );
        // Nayi distance ke mutabiq fare update karein
        await getFareEstimate();
      }
      print('SAHAr: Stop removed, Map and Fare updated.');
    }
  }

  void setRideType(String type) {
    rideType.value = type;
    isMultiStopRide.value = type == 'Multi-Stop Ride';
  }

  // Delegate to LocationService
  Future<void> setPickupToCurrentLocation() async {
    try {
      await _locationService.getCurrentLocation();
      LocationData? currentLocationData = _locationService.getCurrentLocationData();
      if (currentLocationData != null) {
        pickupController.text = currentLocationData.address;
        pickupLocation.value = currentLocationData;

        _hasShownServiceUnavailable = false;
      } else {
        //Get.snackbar('Error', 'Could not get current location');
      }
    } catch (e) {
      // Get.snackbar('Error', 'Failed to get current location: $e');
    }
  }

  // Core ride booking logic
  Future<void> bookRide() async {
    if (!_validateRideBooking()) return;

    try {
      isLoading.value = true;

      // Create route visualization
      await _mapService.createRouteMarkersAndPolylines(
        pickupLocation: pickupLocation.value,
        dropoffLocation: dropoffLocation.value,
        additionalStops: additionalStops,
      );

      isRideBooked.value = true;
      rideStatus.value = RideStatus.booked;

      String scheduleInfo = _getScheduleInfo();
      Get.snackbar(
        'Success',
        'Route calculated!\nDistance: ${_mapService.routeDistance.value}\nDuration: ${_mapService.routeDuration.value}$scheduleInfo',
        duration: const Duration(seconds: 5),
      );
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Booking failed: $e');
      isRideBooked.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED: Start ride with proper API structure
  Future<void> startRide([String? paymentToken]) async {
    print(' SAHArSAHAr startRide() called');


    if (!isRideBooked.value) {
      print(' SAHArSAHAr Ride not booked yet');
      Get.snackbar('Error', 'Please book a ride first');
      return;
    }

    if (pickupLocation.value == null || dropoffLocation.value == null) {
      print(' SAHArSAHAr Missing pickup or dropoff location');
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return;
    }

    // Validate scheduled ride requirements
    if (isScheduled.value) {
      if (scheduledDate.value == null || scheduledTime.value == null) {
        Get.snackbar('Incomplete Schedule', 'Please set both date and time');
        return;
      }

      DateTime scheduledDateTime = getScheduledDateTime()!;
      if (scheduledDateTime.isBefore(DateTime.now())) {
        Get.snackbar('Invalid Schedule', 'Scheduled time cannot be in the past');
        return;
      }
    }

    try {
      isLoading.value = true;
      print(' SAHArSAHAr Preparing stops...');

      List<Map<String, dynamic>> allStops = [];

      // Pickup
      allStops.add({
        "stopOrder": 0,
        "location": pickupLocation.value!.address,
        "latitude": pickupLocation.value!.latitude,
        "longitude": pickupLocation.value!.longitude,
      });
      print(' SAHArSAHAr Added pickup: ${pickupLocation.value!.address}');

      // Additional stops
      for (int i = 0; i < additionalStops.length; i++) {
        final stop = additionalStops[i];
        if (stop.address.isNotEmpty) {
          allStops.add({
            "stopOrder": i + 1,
            "location": stop.address,
            "latitude": stop.latitude,
            "longitude": stop.longitude,
          });
          print(' SAHArSAHAr Added stop ${i + 1}: ${stop.address}');
        }
      }

      // Dropoff
      allStops.add({
        "stopOrder": allStops.length,
        "location": dropoffLocation.value!.address,
        "latitude": dropoffLocation.value!.latitude,
        "longitude": dropoffLocation.value!.longitude,
      });
      print(' SAHArSAHAr Added dropoff: ${dropoffLocation.value!.address}');

      DateTime scheduledDateTime = isScheduled.value && getScheduledDateTime() != null
          ? getScheduledDateTime()!
          : DateTime.now();

      var userId = await SharedPrefsService.getUserId() ?? AppConstants.defaultUserId;

      Map<String, dynamic> requestData = {
        "userId": userId,
        "rideType": rideType.value,
        "isScheduled": isScheduled.value,
        "scheduledTime": scheduledDateTime.toIso8601String(),
        "passengerCount": passengerCount.value,
        "fareEstimate": estimatedFare.value,
        "promoCode": appliedPromoCode.value,
        "paymentToken": paymentToken ?? '',
        "stops": allStops,
      };
      if (appliedPromoCodeId.value.isNotEmpty) {
        requestData["promoCodeId"] = appliedPromoCodeId.value;
      }

      print(' SAHArSAHAr Request payload: $requestData');

      // Set appropriate status based on ride type
      rideStatus.value = isScheduled.value ? RideStatus.waiting : RideStatus.waiting;

      Response response = await _apiProvider.postData(ApiEndpoints.bookRide, requestData);
      print(' SAHArSAHAr API response: ${response.body}');

      if (response.isOk) {
        await _handleRideResponse(response);
      } else {
        rideStatus.value = RideStatus.cancelled;
        Get.snackbar('Error', 'Failed to start ride: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr Exception caught: $e');
      rideStatus.value = RideStatus.cancelled;
      Get.snackbar('Error', 'Failed to start ride: $e');
    } finally {
      isLoading.value = false;
      print(' SAHArSAHAr Ride booking process completed');
    }
  }

  // FIXED: Start trip functionality with proper endpoint
  Future<void> startTrip() async {
    if (currentRideId.value.isEmpty) {
      Get.snackbar('Error', 'Ride ID not found');
      return;
    }

    try {
      isLoading.value = true;

      String endpoint = ApiEndpoints.startTrip.replaceAll('{rideId}', currentRideId.value);
      Response response = await _apiProvider.postData(endpoint, {});

      if (response.isOk) {
        rideStatus.value = RideStatus.tripStarted;

        // Add this line to start the timer locally!
        localRideStartTime.value = DateTime.now();
        localRideEndTime.value = null; // Reset end time just in case

        // Enable destination tracking when trip starts
        isTrackingDestination.value = true;
        _updateDistanceToDestination(); // Calculate initial distance
        print(' SAHAr Trip started - destination tracking enabled');
      } else {
        Get.snackbar('Error', 'Failed to Start Ride: ${response.statusText}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to Start Ride: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED: End trip functionality with proper endpoint
  Future<void> endTrip() async {
    print(' SAHArSAHAr endTrip() method called');
    if (currentRideId.value.isEmpty) {
      Get.snackbar('Error', 'Ride ID not found');
      return;
    }

    // Show loading payment popup while ending trip and preparing payment
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 44,
                width: 44,
                child: CircularProgressIndicator(
                  color: MColor.primaryNavy,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ride completed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MColor.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading payment...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      isLoading.value = true;
      print(' SAHArSAHAr Ending trip with ride ID: ${currentRideId.value}');

      String endpoint = ApiEndpoints.endTrip.replaceAll('{rideId}', currentRideId.value);
      Response response = await _apiProvider.postData(endpoint, {});

      if (response.isOk) {
        print(' SAHArSAHAr Trip ended successfully: ${response.body}');
        prevRideId.value = currentRideId.value;

        // Add this line to stop the timer locally!
        localRideEndTime.value = DateTime.now();

        _handleTripCompletion(response);
      } else {
        if (Get.isDialogOpen == true) Get.back();
        print(' SAHArSAHAr Failed to end trip: ${response.statusText}');
        Get.snackbar('Error', 'Failed to End Ride: ${response.statusText}');
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      print(' SAHArSAHAr Error ending trip: $e');
      Get.snackbar('Error', 'Failed to End Ride: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getFareEstimate() async {
    print('SAHArSAHAr getFareEstimate() method called');

    try {
      isLoading.value = true;

      String routeDistanceStr = _mapService.routeDistance.value;
      print('SAHArSAHAr routeDistanceStr: $routeDistanceStr');

      if (routeDistanceStr.isEmpty) {
        print('SAHArSAHAr Route distance is empty');
        return;
      }

      // Extract numeric distance
      String numericPart = routeDistanceStr.split(' ').first;
      double distance = double.tryParse(numericPart) ?? 0.0;
      print('SAHArSAHAr Parsed distance: $distance');

      // Get pickup address
      String address = pickupLocation.value?.address ?? '';
      print('SAHArSAHAr Pickup address: $address');

      if (address.isEmpty) {
        print('SAHArSAHAr Pickup address is empty');
        return;
      }

      // Duration (static for now)
      String duration = "0.0";

      // Query: Address + distance + duration. Body: promo (and optional distance for APIs that read POST only).
      final String endpoint =
          "${ApiEndpoints.fareEstimate}?Address=${Uri.encodeComponent(address)}&distance=$distance&duration=$duration";

      final Map<String, dynamic> fareEstimateBody = {
        'distance': distance,
        'duration': double.tryParse(duration) ?? 0.0,
      };
      if (appliedPromoCodeId.value.isNotEmpty) {
        fareEstimateBody['promoCodeId'] = appliedPromoCodeId.value;
      } else if (appliedPromoCode.value.isNotEmpty) {
        fareEstimateBody['promoCode'] = appliedPromoCode.value;
      }

      print('SAHArSAHAr Calling fareEstimate API: $endpoint body=$fareEstimateBody');

      Response response = await _apiProvider.postData(endpoint, fareEstimateBody);

      if (response.isOk) {
        print('SAHArSAHAr Fare estimate response: ${response.body}');

        var responseBody = response.body;
        if (responseBody is! Map<String, dynamic>) {
          print('SAHArSAHAr Unexpected fare response shape');
          return;
        }

        // New flat shape: subtotal, discount, total, currency, adminPercentage, message
        if (responseBody.containsKey('total')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            fareBreakdownAvailable.value = true;
            fareSubtotal.value = _parseFareNumber(responseBody['subtotal']);
            fareDiscount.value = _parseFareNumber(responseBody['discount']);
            estimatedFare.value = _parseFareNumber(responseBody['total']);
            fareCurrency.value =
                responseBody['currency']?.toString() ?? fareCurrency.value;
            adminPercentage.value =
                _parseFareNumber(responseBody['adminPercentage']);
            fareMessage.value = responseBody['message']?.toString() ?? '';
            print(
                'SAHArSAHAr Fare (flat): total=${estimatedFare.value} discount=${fareDiscount.value}');
            _syncFareWithVerifiedFlatPromoIfNeeded();
            // Keep [estimatedPrice] aligned with the estimate the user saw. Booking APIs often
            // return a higher `estimatedPrice` (e.g. regional minimum fare) which wrongly
            // replaced this and made $5 estimates show/charge as $15 in the UI.
            estimatedPrice.value = estimatedFare.value;
          });
          return;
        }

        // Check if fare contains error message
        if (responseBody['fare'] is String &&
            responseBody['fare'].toString().contains('Fare settings not found')) {
          print('SAHArSAHAr Fare settings not found for this location');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            estimatedFare.value = 0.0;
            fareSubtotal.value = 0.0;
            fareDiscount.value = 0.0;
            fareBreakdownAvailable.value = false;
          });

          // Only show snackbar if we haven't shown it for this location
          if (!_hasShownServiceUnavailable) {
            _hasShownServiceUnavailable = true;
            Get.snackbar(
              'Service Unavailable',
              'Service is unavailable in your area',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }
          return;
        }

        var fareData = responseBody['fare'] is String
            ? json.decode(responseBody['fare'] as String)
            : responseBody['fare'];

        if (fareData != null && fareData['EstimatedFare'] != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            fareBreakdownAvailable.value = false;
            estimatedFare.value = (fareData['EstimatedFare'] ?? 0.0).toDouble();
            adminPercentage.value =
                (fareData['AdminPercentage'] ?? adminPercentage.value)
                    .toDouble();
            fareSubtotal.value = 0.0;
            fareDiscount.value = 0.0;
            print('SAHArSAHAr Fare updated: ${estimatedFare.value}');
            print('SAHArSAHAr Admin percentage updated: ${adminPercentage.value}');
            _syncFareWithVerifiedFlatPromoIfNeeded();
            estimatedPrice.value = estimatedFare.value;
          });
        } else {
          print('SAHArSAHAr No fare data in response');
          Get.snackbar('Error', 'No fare data received');
        }
      } else {
        print('SAHArSAHAr Failed to fetch fare estimate: ${response.statusText}');
        Get.snackbar('Error', 'Failed to fetch fare estimate: ${response.statusText}');
      }
    } catch (e) {
      print('SAHArSAHAr Error in getFareEstimate: $e');
      //Get.snackbar('Error', 'Failed to get fare estimate: $e');
    } finally {
      isLoading.value = false;
    }
  }


  // Handle ride booking response
  Future<void> _handleRideResponse(Response response) async {
    try {
      var responseBody = response.body;
      print(' SAHArSAHAr Handling ride response: $responseBody');

      if (responseBody is Map<String, dynamic>) {
        // Handle scheduled rides differently
        if (isScheduled.value) {
          // Extract rideId from response for scheduled rides
          // Handle nested structure where rideId might be a Map containing the ride data
          String? scheduledRideId;
          
          if (responseBody.containsKey('rideId')) {
            final rideIdValue = responseBody['rideId'];
            // Check if rideId is a Map (nested structure)
            if (rideIdValue is Map<String, dynamic>) {
              scheduledRideId = rideIdValue['rideId'] as String?;
              scheduledRideId ??= rideIdValue['id'] as String?;
              scheduledRideId ??= rideIdValue['scheduledRideId'] as String?;
            } else if (rideIdValue is String) {
              scheduledRideId = rideIdValue;
            }
          } else if (responseBody.containsKey('id')) {
            final idValue = responseBody['id'];
            if (idValue is Map<String, dynamic>) {
              scheduledRideId = idValue['rideId'] as String?;
              scheduledRideId ??= idValue['id'] as String?;
            } else if (idValue is String) {
              scheduledRideId = idValue;
            }
          } else if (responseBody.containsKey('scheduledRideId')) {
            final scheduledRideIdValue = responseBody['scheduledRideId'];
            if (scheduledRideIdValue is Map<String, dynamic>) {
              scheduledRideId = scheduledRideIdValue['rideId'] as String?;
              scheduledRideId ??= scheduledRideIdValue['id'] as String?;
            } else if (scheduledRideIdValue is String) {
              scheduledRideId = scheduledRideIdValue;
            }
          } else if (responseBody.keys.isNotEmpty) {
            // Try to get rideId from first key's value
            final firstKey = responseBody.keys.first;
            final firstValue = responseBody[firstKey];
            if (firstValue is Map<String, dynamic>) {
              scheduledRideId = firstValue['rideId'] as String?;
              scheduledRideId ??= firstValue['id'] as String?;
              scheduledRideId ??= firstValue['scheduledRideId'] as String?;
            } else if (firstValue is String) {
              scheduledRideId = firstValue;
            }
          }

          // Set rideId if found
          if (scheduledRideId != null && scheduledRideId.isNotEmpty) {
            currentRideId.value = scheduledRideId;
            print('SAHAr: Scheduled ride ID: $scheduledRideId');
          }

          // Save held payment info to backend for scheduled rides
          if (heldPaymentIntentId.value.isNotEmpty && 
              heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
            await _saveHeldPaymentToBackend();
          }

          // Show success toast message
          Get.snackbar(
            'Scheduled Ride Received Successfully!',
            'Your ride has been scheduled for ${DateFormat('MMM dd, yyyy hh:mm a').format(getScheduledDateTime()!)}',
            duration: const Duration(seconds: 5),
            backgroundColor: MColor.primaryNavy.withValues(alpha:0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
          );
          
          // Clear everything after successful scheduled ride
          clearBooking();
          return;
        }

        // Handle immediate rides - check for different response structures
        String rideIdKey = responseBody.keys.first;
        var rideData = responseBody[rideIdKey];

        if (rideData is Map<String, dynamic>) {
          // Driver found - extract driver information
          currentRideId.value = rideData['rideId'] ?? '';
          driverId.value = rideData['driverId'] ?? '';
          driverName.value = rideData['driverName'] ?? '';
          driverPhone.value = rideData['driverPhone'] ?? '';
          vehicleColor.value = rideData['vehicle'] ?? '';
          vehicle.value = rideData['vehicleColor'] ?? '';
          final serverEst = (rideData['estimatedPrice'] ?? 0.0).toDouble();
          // Prefer the in-app fare-estimate total when we have a flat breakdown, so a backend
          // minimum-fare bump does not override the $total the user already saw (e.g. $5 vs $15).
          if (fareBreakdownAvailable.value && estimatedFare.value > 0) {
            estimatedPrice.value = estimatedFare.value;
            if ((serverEst - estimatedFare.value).abs() > 0.02) {
              print(
                  ' SAHArSAHAr Fare: using client estimate \$${estimatedFare.value.toStringAsFixed(2)} '
                  '(server estimatedPrice \$${serverEst.toStringAsFixed(2)})');
            }
          } else {
            estimatedPrice.value =
                serverEst > 0 ? serverEst : estimatedFare.value;
          }
          rideStatus.value = RideStatus.driverAssigned;
          rating.value = (rideData['driverAverageRating'] ?? 0.0).toDouble();

          // IMPORTANT: Extract driver's Stripe Connected Account ID
          driverStripeAccountId.value = rideData['driverStripeAccount'] ?? rideData['driverStripeAccount'] ?? '';

          print(' SAHArSAHAr ✅ Driver found!');
          print(' SAHArSAHAr Driver ID: ${driverId.value}');
          print(' SAHArSAHAr Driver Name: ${driverName.value}');
          print(' SAHArSAHAr Driver Stripe Account: ${driverStripeAccountId.value}');

          if (driverStripeAccountId.value.isEmpty) {
            print(' SAHArSAHAr ⚠️ WARNING: Driver does not have Stripe account!');
          }

          // Set up SignalR subscription for ride updates
          if (currentRideId.value.isNotEmpty) {
            signalRService.subscribeToRide(currentRideId.value);
          }

          // Keep chat notifications working even if user never opens ChatScreen.
          // This ensures ChatBackgroundService knows the active ride + participants.
          try {
            final userId = await SharedPrefsService.getUserId();
            if (userId != null &&
                currentRideId.value.isNotEmpty &&
                driverId.value.isNotEmpty) {
              ChatBackgroundService.to.updateRideInfo(
                rideId: currentRideId.value,
                driverId: driverId.value,
                driverName: driverName.value,
                currentUserId: userId,
                status: rideStatus.value,
              );
            }
          } catch (e) {
            print('⚠️ SAHAr Failed to sync ride info to ChatBackgroundService: $e');
          }

          // Save held payment info to backend now that we have rideId and driverId
          if (heldPaymentIntentId.value.isNotEmpty && 
              heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
            await _saveHeldPaymentToBackend();
          }

          Get.snackbar(
              'Driver Assigned!',
              'Driver ${driverName.value} has been assigned to your ride.'
          );
        } else if (rideData is String && rideData.contains('No live drivers available')) {
          rideStatus.value = RideStatus.noDriver;
        }
      }
    } catch (e) {
      print(' SAHArSAHAr Error handling ride response: $e');
      Get.snackbar('Error', 'Failed to process ride response: $e');
    }
  }

  void _handleTripCompletion(Response response) {
    var responseBody = response.body;
    print(' SAHArSAHAr Processing trip completion response: $responseBody');

    // Dismiss loading payment popup before showing payment dialog
    if (Get.isDialogOpen == true) Get.back();

    String? completionRid;
    if (responseBody is Map<String, dynamic>) {
      final msg = responseBody['message'];
      if (msg is Map<String, dynamic>) {
        completionRid = msg['rideId']?.toString();
      }
      completionRid ??= responseBody['rideId']?.toString();
    }
    completionRid ??= currentRideId.value;
    if (completionRid.isNotEmpty &&
        _fareCaptureCompletedRideId.isNotEmpty &&
        _fareCaptureCompletedRideId == completionRid) {
      print(
          'SAHAr: trip completion skipped — fare already settled for ride $completionRid (e.g. FCM auto-pay)');
      rideStatus.value = RideStatus.tripCompleted;
      return;
    }

    // Always set the status to completed first
    rideStatus.value = RideStatus.tripCompleted;

    if (responseBody is Map<String, dynamic>) {
      // Handle different response structures
      if (responseBody.containsKey('message')) {
        var messageData = responseBody['message'];
        if (messageData is Map<String, dynamic>) {
          _showPaymentDialog(messageData);
          return;
        }
      }

      // Check if response has direct trip data
      if (responseBody.containsKey('finalFare') || responseBody.containsKey('totalFare')) {
        _showPaymentDialog(responseBody);
        return;
      }
    }

    // Fallback if no proper response data
    Get.snackbar('Trip Completed', 'Your trip has ended successfully!');
  }

  Future<void> _showPaymentDialog(Map<String, dynamic> tripData) async {
    print(' SAHArSAHAr Showing payment dialog with data: $tripData');
    prevRideId.value = tripData['rideId'];
    String rideId = tripData['rideId'] ?? currentRideId.value;
    double finalFare = (tripData['finalFare'] ?? tripData['totalFare'] ?? estimatedPrice.value).toDouble();
    finalFare = _roundMoney2(finalFare);
    double distance = (tripData['distance'] ?? 0.0).toDouble();
    String rideStartTime = tripData['rideStartTime'] ?? '';
    String rideEndTime = tripData['rideEndTime'] ?? '';
    String duration = tripData['duration'] ?? tripData['totalWaitingTime'] ?? '';

    // Store actual fare before balance deduction
    actualFareBeforeBalance.value = finalFare;

    final quotedFromTrip = _parseFareNumber(
        tripData['fareEstimate'] ?? tripData['estimatedFare']);
    final quoted = quotedFromTrip > 0
        ? _roundMoney2(quotedFromTrip)
        : _roundMoney2(estimatedFare.value);
    _reconcileHeldAmountWhenQuoteMatchesFinal(finalFare, quoted);

    // Amount pre-authorized on the card (Stripe hold), not [estimatedPrice] which may differ.
    double originalHeldAmount =
        _heldAmount > 0 ? _heldAmount : estimatedPrice.value;

    // Update estimated price with actual final fare from API
    estimatedPrice.value = finalFare;

    // Calculate the difference (held amount - final fare)
    double heldPaymentDifference = originalHeldAmount - finalFare;

    print(' SAHArSAHAr 💰 Actual Fare: \$${finalFare.toStringAsFixed(2)}');
    print(
        ' SAHArSAHAr 💳 Pre-authorized: \$${originalHeldAmount.toStringAsFixed(2)} · '
        'Difference (held − fare): \$${heldPaymentDifference.toStringAsFixed(2)}');

    // Store payment dialog data for potential re-opening
    _paymentDialogData = {
      'rideId': rideId,
      'finalFare': finalFare,
      'distance': distance,
      'duration': duration,
      'rideStartTime': rideStartTime,
      'rideEndTime': rideEndTime,
      'originalHeldAmount': originalHeldAmount,
      'heldPaymentDifference': heldPaymentDifference,
    };

    await _persistPendingPaymentState();

    _showPaymentPopup(
      rideId: rideId,
      finalFare: finalFare,
      distance: distance,
      duration: duration,
      rideStartTime: rideStartTime,
      rideEndTime: rideEndTime,
      originalHeldAmount: originalHeldAmount,
      heldPaymentDifference: heldPaymentDifference,
    );
  }

  Future<double> calculatePrice(double finalFare) async {

    print(' SAHArSAHAr 📊 Final Fare: \$${finalFare.toStringAsFixed(2)}');

    return finalFare > 0 ? finalFare : 0;
  }


  // Enhanced payment methods with better UI
  void _showPaymentPopup({
    required String rideId,
    required double finalFare,
    required double distance,
    required String duration,
    required String rideStartTime,
    required String rideEndTime,
    required double originalHeldAmount,
    required double heldPaymentDifference,
  }) {
    // Reset ride duration display
    rideDurationDisplay.value = 'Calculating...';
    Timer? durationTimer;

    // Function to calculate and format duration locally
    String calculateRideDuration() {
      try {
        // Use our manual local start time if we have it
        if (localRideStartTime.value != null) {
          DateTime startTime = localRideStartTime.value!;
          // If the ride ended, use the end time. Otherwise, keep ticking with DateTime.now()
          DateTime endTime = localRideEndTime.value ?? DateTime.now();

          Duration difference = endTime.difference(startTime);
          int hours = difference.inHours;
          int minutes = difference.inMinutes.remainder(60);
          int seconds = difference.inSeconds.remainder(60);

          // Format with double digits
          if (hours > 0) {
            return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
          } else if (minutes > 0) {
            return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
          } else {
            return '${seconds.toString().padLeft(2, '0')}s';
          }
        }

        // Fallback just in case local variables are null
        return duration.isNotEmpty ? duration : '0s';
      } catch (e) {
        print('Error calculating ride duration: $e');
        return '0s';
      }
    }

    // Initialize duration display
    rideDurationDisplay.value = calculateRideDuration();

    // Update duration every second if needed (for live updates)
    durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      rideDurationDisplay.value = calculateRideDuration();
    });

    Get.dialog(
      PopScope(
        canPop: false, // Prevent back button dismissal - Payment is mandatory
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: MColor.primaryNavy, size: 28),
              SizedBox(width: 8),
              Text('Trip Completed!', style: TextStyle(color: MColor.primaryNavy, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              // Bound the dialog content height so it can scroll instead of overflowing
              maxHeight: Get.height * 0.55,
              maxWidth: Get.width * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Summary Card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        _buildSummaryRow('Distance', distance > 0 ? '${distance.toStringAsFixed(2)} km' : 'N/A'),
                        SizedBox(height: 8),
                        Obx(() => _buildSummaryRow('Duration', rideDurationDisplay.value)),
                        SizedBox(height: 8),
                        _buildSummaryRow('Already Paid', originalHeldAmount > 0 ? '\$${originalHeldAmount.toStringAsFixed(2)}' : '\$0.00'),
                        SizedBox(height: 8),
                        _buildSummaryRow('Fare', finalFare <= 0 ? '\$0.00' : '\$${finalFare.toStringAsFixed(2)}'),
                        Obx(() => selectedTipAmount.value > 0
                            ? Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: _buildSummaryRow('Tip', '\$${selectedTipAmount.value.toStringAsFixed(2)}'),
                              )
                            : SizedBox.shrink()),
                        SizedBox(height: 12),
                        Divider(),
                        SizedBox(height: 8),
                        Obx(() {
                          double totalAmount = finalFare + selectedTipAmount.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(
                                totalAmount <= 0 ? "\$0.00" : "\$${totalAmount.toStringAsFixed(2)}",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MColor.primaryNavy),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        actions: [
          // Payment buttons
          Obx(() => Column(
            children: [
              if (!isLoading.value) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: MColor.primaryNavy),
                    ),
                    onPressed: () {
                      Get.back();
                      _showTipDialog(finalFare <= 0 ? 0 : finalFare, originalHeldAmount);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8),
                        Obx(() => Text(
                          selectedTipAmount.value > 0 ? 'Change Tip' : 'Add Tip',
                          style: TextStyle(color: MColor.primaryNavy, fontWeight: FontWeight.w500)
                        )),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColor.primaryNavy,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      // Don't close dialog - let payment completion handle it
                      await _completePayment(finalFare, tipAmount: selectedTipAmount.value);
                    },
                    child: Obx(() {
                      double totalWithTip = finalFare + selectedTipAmount.value;
                      double amountToPay = totalWithTip - originalHeldAmount;
                      // Float noise only (reconciliation fixes real \$0.10 hold drift).
                      if (amountToPay.abs() < 0.02) amountToPay = 0;

                      String buttonText;
                      if (amountToPay <= 0) {
                        buttonText = 'Complete Ride';
                      } else {
                        buttonText = "Pay \$${amountToPay.toStringAsFixed(2)}";
                      }
                      
                      return Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ] else ...[
                // Show loading indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(MColor.primaryNavy),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing payment...',
                        style: TextStyle(
                          fontSize: 16,
                          color: MColor.primaryNavy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait, do not close this window',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          )),
        ],
        ),
      ), // End of AlertDialog
      barrierDismissible: false,
    ).then((_) {
      // Clean up timer when dialog is closed
      durationTimer?.cancel();
    });
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showTipDialog(double finalFare, double originalHeldAmount) {
    // Ensure finalFare is never negative
    if (finalFare < 0) {
      finalFare = 0.0;
    }

    // Initialize with current selected tip if any
    RxDouble selectedTip = selectedTipAmount.value.obs;
    List<double> tipOptions = AppConstants.tipPercentages;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            SizedBox(width: 8),
            Text('Add Tip', style: TextStyle(color: MColor.primaryNavy, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show your appreciation to ${driverName.value}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),

              // Tip amount display
              Obx(() => Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MColor.primaryNavy.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Fare: \$${finalFare.toStringAsFixed(2)}'),
                    if (selectedTip.value > 0) ...[
                      Text('Tip: \$${selectedTip.value.toStringAsFixed(2)}',
                          style: TextStyle(color: MColor.primaryNavy)),
                    ],
                    Divider(),
                    Text('Total: \$${(finalFare + selectedTip.value).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),

              SizedBox(height: 20),

              // Tip options
              Text('Select tip amount:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              Obx(() => Wrap(
                spacing: 8,
                children: tipOptions.map((tip) =>
                    ChoiceChip(
                      label: Text('\$${tip.toStringAsFixed(0)}'),
                      selected: selectedTip.value == tip,
                      onSelected: (selected) {
                        if (selected) selectedTip.value = tip;
                      },
                      selectedColor: MColor.primaryNavy.withValues(alpha:0.3),
                      labelStyle: TextStyle(
                        color: selectedTip.value == tip ? MColor.primaryNavy : Colors.black,
                        fontWeight: selectedTip.value == tip ? FontWeight.bold : FontWeight.normal,
                      ),
                    )
                ).toList(),
              )),

              SizedBox(height: 16),

              // Custom tip input
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Custom tip amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MColor.primaryNavy),
                  ),
                  labelStyle: TextStyle(color: MColor.primaryNavy),
                ),
                onChanged: (value) {
                  double? customTip = double.tryParse(value);
                  if (customTip != null && customTip >= 0) {
                    selectedTip.value = customTip;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text('Cancel', style: TextStyle(color: MColor.primaryNavy)),
              ),
              Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColor.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Store selected tip and return to payment dialog
                  selectedTipAmount.value = selectedTip.value;
                  Get.back();
                  
                  // Re-open payment dialog with tip included if we have stored data
                  if (_paymentDialogData != null) {
                    _showPaymentPopup(
                      rideId: _paymentDialogData!['rideId'],
                      finalFare: _paymentDialogData!['finalFare'],
                      distance: _paymentDialogData!['distance'],
                      duration: _paymentDialogData!['duration'],
                      rideStartTime: _paymentDialogData!['rideStartTime'],
                      rideEndTime: _paymentDialogData!['rideEndTime'],
                      originalHeldAmount: _paymentDialogData!['originalHeldAmount'],
                      heldPaymentDifference: _paymentDialogData!['heldPaymentDifference'],
                    );
                  }
                },
                child: Text(
                  selectedTip.value > 0 ? 'Confirm Tip' : 'No Tip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }



  // FIXED: Submit tip with proper API structure
  Future<void> _submitTip(double tipAmount, double finalFare, double totalAmount) async {
    print(' SAHArSAHAr 🟡 _submitTip() called');
    print(' SAHArSAHAr 💰 Tip Amount: \$${tipAmount.toStringAsFixed(2)}');
    print(' SAHArSAHAr 🧾 Final Fare: \$${finalFare.toStringAsFixed(2)}');
    print(' SAHArSAHAr 📊 Total Amount: \$${totalAmount.toStringAsFixed(2)}');

    try {
      isLoading.value = true;
      print(' SAHArSAHAr ⏳ isLoading set to true');

      var userId = await SharedPrefsService.getUserId() ?? AppConstants.defaultUserId;

      Map<String, dynamic> tipData = {
        "rideId": prevRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "amount": tipAmount,
        "createdAt": DateTime.now().toIso8601String(),
      };

      print(' SAHArSAHAr 📦 Tip Payload: $tipData');

      Response response = await _apiProvider.postData(ApiEndpoints.submitTip, tipData);
      print(' SAHArSAHAr 📥 API Response: ${response.body}');

      if (response.isOk) {
        print(' SAHArSAHAr ✅ Tip submitted successfully');
        Get.snackbar(
          'Tip Added!',
          'Tip of \$${tipAmount.toStringAsFixed(2)} added for ${driverName.value}!',
          duration: Duration(seconds: 3),
          backgroundColor: MColor.primaryNavy.withValues(alpha:0.8),
          colorText: Colors.white,
        );
      } else {
        print(' SAHArSAHAr ❌ Tip submission failed: ${response.statusText}');
        Get.snackbar('Error', 'Failed to process tip: ${response.statusText}');
      }
    } catch (e) {
      print(' SAHArSAHAr 🔥 Exception during tip submission: $e');
      Get.snackbar('Error', 'Failed to process tip: $e');
    } finally {
      isLoading.value = false;
      print(' SAHArSAHAr ✅ isLoading set to false');
    }
  }

  // Show review/feedback dialog
  void _showReviewDialog() {
    RxInt selectedRating = 0.obs;
    TextEditingController commentController = TextEditingController();

    Get.dialog(
      PopScope(
        canPop: true, // Allow back button dismissal - Review is optional (Uber style)
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            // User pressed back button to skip review
            print(' SAHArSAHAr ℹ️ User skipped review via back button');
            clearBooking(); // Reset app to home
          }
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.star, color: MColor.trackingOrange, size: 28),
              SizedBox(width: 8),
              Text('Rate Your Rider',
                  style: TextStyle(
                    color: MColor.primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )
              ),
            ],
          ),
        content: Container(
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your ride with ${driverName.value}?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Star rating
              Obx(() => FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating.value ? Icons.star : Icons.star_border,
                        size: 24,
                        color: MColor.trackingOrange,
                      ),
                      onPressed: () {
                        selectedRating.value = index + 1;
                      },
                    );
                  }),
                ),
              )),

              SizedBox(height: 20),

              // Comment field
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  filled: true,
                  fillColor: MColor.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MColor.lightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MColor.primaryNavy, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print(' SAHArSAHAr ℹ️ User clicked Skip button');
              // Close review dialog and reset app
              Get.back(closeOverlays: true);
              clearBooking();
            },
            child: Text('Skip', style: TextStyle(color: MColor.mediumGrey)),
          ),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MColor.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: (selectedRating.value > 0 && !isLoading.value) ? () async {
              print(' SAHArSAHAr 🔵 Submit Review button clicked');

              // Submit feedback API call
              final result = await _submitFeedback(
                  selectedRating.value,
                  commentController.text.trim()
              );

              print(' SAHArSAHAr 🔵 Closing dialog with closeOverlays: true');
              // CRITICAL: Close ALL overlays (dialog + any snackbars)
              Get.back(closeOverlays: true);

              print(' SAHArSAHAr 🔵 Dialog closed, now showing result snackbar');
              // Now show the result snackbar (after dialog is closed)
              if (result['success'] == true) {
                // Show thank you dialog with confetti animation
                showThankYouDialog(result['message']);
              } else {
                Get.snackbar(
                  'Error',
                  result['message'],
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  colorText: Colors.white,
                );
              }

              print(' SAHArSAHAr 🔵 Calling clearBooking to reset app');
              // Reset app to home screen
              clearBooking();
            } : null,
            child: isLoading.value
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit Review',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
          )),
        ],
        ),
      ), // End of AlertDialog
      barrierDismissible: false,
    );
  }

  // Submit feedback to API
  // Returns Map with 'success' (bool) and 'message' (String)
  Future<Map<String, dynamic>> _submitFeedback(int rating, String comments) async {
    print(' SAHArSAHAr 🟡 _submitFeedback() called');
    print(' SAHArSAHAr ⭐ Rating: $rating');
    print(' SAHArSAHAr 💬 Comments: $comments');

    try {
      isLoading.value = true;
      print(' SAHArSAHAr ⏳ isLoading set to true');

      var userId = await SharedPrefsService.getUserId() ?? AppConstants.defaultUserId;
      var userName = await SharedPrefsService.getUserFullName() ?? AppConstants.defaultUserName;

      Map<String, dynamic> feedbackData = {
        "rideId": prevRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "rating": rating,
        "comments": comments.isEmpty ? null : comments,
        "createdAt": DateTime.now().toIso8601String(),
        "feedbackFrom": "User",
        "driverName": driverName.value,
        "userName": userName,
      };

      print(' SAHArSAHAr 📦 Feedback Payload: $feedbackData');

      Response response = await _apiProvider.postData(ApiEndpoints.submitFeedback, feedbackData);
      print(' SAHArSAHAr 📥 API Response: ${response.body}');

      if (response.isOk) {
        print(' SAHArSAHAr ✅ Feedback submitted successfully');
        return {
          'success': true,
          'message': 'Your feedback has been submitted successfully!'
        };
      } else {
        print(' SAHArSAHAr ❌ Feedback submission failed: ${response.statusText}');
        return {
          'success': false,
          'message': 'Failed to submit feedback: ${response.statusText}'
        };
      }
    } catch (e) {
      print(' SAHArSAHAr 🔥 Exception during feedback submission: $e');
      return {
        'success': false,
        'message': 'Failed to submit feedback: $e'
      };
    } finally {
      isLoading.value = false;
      print(' SAHArSAHAr ✅ isLoading set to false');
    }
  }

  // Validation methods
  bool _validateRideBooking() {
    if (pickupLocation.value == null || dropoffLocation.value == null) {
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return false;
    }

    if (isScheduled.value) {
      if (scheduledDate.value == null || scheduledTime.value == null) {
        Get.snackbar('Error', 'Please select both date and time for scheduled ride');
        return false;
      }

      DateTime scheduledDateTime = getScheduledDateTime()!;
      if (scheduledDateTime.isBefore(DateTime.now())) {
        Get.snackbar('Error', 'Scheduled time cannot be in the past');
        return false;
      }
    }

    return true;
  }

  String _getScheduleInfo() {
    if (isScheduled.value && scheduledDate.value != null && scheduledTime.value != null) {
      DateTime scheduledDateTime = getScheduledDateTime()!;
      return '\nScheduled: ${DateFormat('MMM dd, yyyy hh:mm a').format(scheduledDateTime)}';
    }
    return '';
  }

  // Delegate to SearchService
  Future<void> searchLocation(String query, String fieldType) async {
    await _searchService.searchLocation(query, fieldType);
  }

  // Handle search suggestion selection
  Future<void> selectSuggestion(AutocompletePrediction prediction) async {
    try {
      isLoading.value = true;
      _searchService.searchSuggestions.clear();

      PlaceDetails? placeDetails = await _searchService.getPlaceDetails(prediction.placeId);
      if (placeDetails == null) return;

      String activeField = _searchService.activeSearchField.value;

      if (activeField == 'pickup') {
        _setPickupLocation(placeDetails);
      } else if (activeField == 'dropoff') {
        _setDropoffLocation(placeDetails);
      } else if (activeField.startsWith('stop_')) {
        _setStopLocation(activeField, placeDetails);
      }

      _searchService.activeSearchField.value = '';
    } catch (e) {
      Get.snackbar('Error', 'Failed to select location');
    } finally {
      isLoading.value = false;
    }
  }

  void _setPickupLocation(PlaceDetails placeDetails) {
    pickupController.text = placeDetails.formattedAddress;
    pickupLocation.value = LocationData(
      address: placeDetails.formattedAddress,
      latitude: placeDetails.location.latitude,
      longitude: placeDetails.location.longitude,
      stopOrder: 0,
    );

    _hasShownServiceUnavailable = false;
  }

  void _setDropoffLocation(PlaceDetails placeDetails) {
    dropoffController.text = placeDetails.formattedAddress;
    dropoffLocation.value = LocationData(
      address: placeDetails.formattedAddress,
      latitude: placeDetails.location.latitude,
      longitude: placeDetails.location.longitude,
      stopOrder: 1,
    );
  }

  void _setStopLocation(String activeField, PlaceDetails placeDetails) {
    int stopIndex = int.parse(activeField.split('_')[1]);
    if (stopIndex < stopControllers.length) {
      stopControllers[stopIndex].text = placeDetails.formattedAddress;

      LocationData stopData = LocationData(
        address: placeDetails.formattedAddress,
        latitude: placeDetails.location.latitude,
        longitude: placeDetails.location.longitude,
        stopOrder: stopIndex + 1,
      );

      if (stopIndex < additionalStops.length) {
        additionalStops[stopIndex] = stopData;
      } else {
        additionalStops.add(stopData);
      }
    }
  }

  // Scheduling
  void toggleScheduling() {
    isScheduled.value = !isScheduled.value;
    if (!isScheduled.value) {
      scheduledDate.value = null;
      scheduledTime.value = null;
    }
  }

  void setScheduledDate(DateTime date) => scheduledDate.value = date;
  void setScheduledTime(TimeOfDay time) => scheduledTime.value = time;

  DateTime? getScheduledDateTime() {
    if (scheduledDate.value != null && scheduledTime.value != null) {
      return DateTime(
        scheduledDate.value!.year,
        scheduledDate.value!.month,
        scheduledDate.value!.day,
        scheduledTime.value!.hour,
        scheduledTime.value!.minute,
      );
    }
    return null;
  }

  // Delegate to MapService
  void setMapController(GoogleMapController controller) {
    _mapService.setMapController(controller);
  }

  Future<void> showPickupLocationWithZoom() async {
    await _mapService.showPickupLocationWithZoom(pickupLocation.value);
  }

  Future<void> centerOnCurrentLocation() async {
    LatLng? currentLatLng = _locationService.currentLatLng.value;
    if (currentLatLng != null) {
      await _mapService.animateToLocation(currentLatLng);
      Get.snackbar('Current Location', 'Centered on your location');
    }
  }

  // Cleanup and reset
  void resetForm() {
    pickupController.clear();
    dropoffController.clear();
    for (var controller in stopControllers) {
      controller.dispose();
    }
    stopControllers.clear();
    additionalStops.clear();
    pickupLocation.value = null;
    dropoffLocation.value = null;
    passengerCount.value = 1;
    _searchService.clearSearchResults();
    currentRideId.value = '';
    rideStatus.value = RideStatus.pending;
    isScheduled.value = false;
    scheduledDate.value = null;
    scheduledTime.value = null;
    signalRService.unsubscribeFromRide();
    isRideBooked.value = false;
    driverLatitude.value = 0.0;
    driverLongitude.value = 0.0;
    isDriverLocationActive.value = false;

    // Reset destination tracking
    isTrackingDestination.value = false;
    distanceToDestination.value = 0.0;

    // Add these two lines at the end of resetForm():
    localRideStartTime.value = null;
    localRideEndTime.value = null;

    promoCodeController.clear();
    _clearAppliedPromo();
    promoError.value = '';
    _fareCaptureCompletedRideId = '';
    estimatedFare.value = 0.0;
    fareSubtotal.value = 0.0;
    fareDiscount.value = 0.0;
    fareBreakdownAvailable.value = false;
    fareMessage.value = '';
    fareCurrency.value = 'CAD';
    adminPercentage.value = 0.0;
  }

  void clearBooking() {
    _mapService.clearMap();
    isRideBooked.value = false;
    rideStatus.value = RideStatus.pending;
    resetForm();
    _locationService.getCurrentLocation();

    // Reset notification flags for next ride
    hasShownApproachingNotification.value = false;
    hasShownArrivedNotification.value = false;

    // Reset destination tracking
    isTrackingDestination.value = false;
    distanceToDestination.value = 0.0;
  }

  /// STEP 1: Hold payment first, then start the ride (book/find driver or schedule)
  Future<void> startRideWithPayment() async {
    print('SAHAr: startRideWithPayment() called');

    // Validations
    if (! isRideBooked. value) {
      print('SAHAr: Ride not booked yet');
      Get.snackbar('Error', 'Please book a ride first');
      return;
    }

    if (pickupLocation.value == null || dropoffLocation.value == null) {
      print('SAHAr: Missing pickup or dropoff location');
      Get.snackbar('Error', 'Please set pickup and dropoff locations');
      return;
    }

    if (isScheduled.value) {
      if (scheduledDate.value == null || scheduledTime.value == null) {
        Get.snackbar('Incomplete Schedule', 'Please set both date and time');
        return;
      }

      DateTime scheduledDateTime = getScheduledDateTime()! ;
      if (scheduledDateTime.isBefore(DateTime.now())) {
        Get.snackbar('Invalid Schedule', 'Scheduled time cannot be in the past');
        return;
      }
    }

    try {
      isLoading.value = true;

      // Use the estimated fare for payment hold
      double amountToHold = (estimatedFare.value > 0)
          ? estimatedFare. value
          : estimatedPrice.value;

      print('SAHAr: Holding payment amount: $amountToHold');

      // Store the amount being held
      _heldAmount = amountToHold;

      // HOLD the payment (not capture yet)
      bool paymentHeld = await _holdStripePayment(amountToHold);

      if (!paymentHeld) {
        print('SAHAr: Payment hold failed or cancelled');
        return; // Error already shown in _holdStripePayment
      }

      print('SAHAr: ✅ Payment held successfully! ');
      print('SAHAr: Payment Intent ID: ${heldPaymentIntentId.value}');

      // Now proceed to start the ride (find driver)
      // Note: We'll save held payment to backend AFTER ride is created (in _handleRideResponse)
      await startRide(heldPaymentIntentId.value); // Pass payment intent as token

    } catch (e) {
      print('SAHAr: Exception in startRideWithPayment:  $e');
      Get.snackbar('Error', 'Failed to process payment/start ride: $e');
    } finally {
      isLoading.value = false;
      print('SAHAr: startRideWithPayment completed');
    }
  }

  /// HOLD payment (authorize without capturing)
  Future<bool> _holdStripePayment(double amount) async {
    try {
      print('SAHAr: Starting _holdStripePayment with amount: $amount');

      if (amount <= 0) {
        print('SAHAr:  Amount is 0 or negative, no payment hold needed');
        heldPaymentIntentId.value = 'NO_PAYMENT_REQUIRED';
        return true;
      }

      int amountInCents = (amount * 100).round();
      print('SAHAr:  Converted amount to cents: $amountInCents');

      // Create payment intent with HOLD (manual capture)
      Map<String, dynamic>? paymentIntent =
      await PaymentService.createPaymentIntentWithHold(
        amount: amountInCents. toString(),
        currency: 'cad',
        description: 'Ride payment - On Hold',
      );

      if (paymentIntent == null) {
        print('SAHAr:  Failed to create payment intent');
        Get.snackbar('Error', 'Failed to create payment hold');
        return false;
      }

      print('SAHAr: Received paymentIntent: $paymentIntent');
      String paymentIntentId = paymentIntent['id'] ?? '';
      print('SAHAr: Payment Intent ID: $paymentIntentId');

      // Show Stripe payment sheet to authorize payment
      var userName = await SharedPrefsService.getUserFullName() ??
          AppConstants.defaultUserName;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: userName,
        ),
      );

      print('SAHAr: Payment sheet initialized');

      await Stripe.instance.presentPaymentSheet();
      print('SAHAr: Payment sheet presented successfully');

      // Save payment intent ID
      heldPaymentIntentId.value = paymentIntentId;

      print('SAHAr: ✅ Payment authorized and held! ');
      return true;

    } on StripeException catch (e) {
      print('SAHAr:  StripeException: ${e. error.localizedMessage}');
      Get.snackbar('Payment Cancelled', 'Payment authorization was cancelled');
      return false;
    } catch (e) {
      print('SAHAr: Error in _holdStripePayment:  $e');
      Get.snackbar('Payment Error', 'Failed to authorize payment: $e');
      return false;
    }
  }

  /// Save held payment info to backend (non-blocking)
  /// This should be called AFTER ride is created (when rideId and driverId are available)
  Future<void> _saveHeldPaymentToBackend() async {
    try {
      var userId = await SharedPrefsService.getUserId() ??
          AppConstants.defaultUserId;

      // Ensure we have required fields
      String rideId = currentRideId.value.isNotEmpty ? currentRideId.value : prevRideId.value;
      if (rideId.isEmpty) {
        print('SAHAr: ⚠️ Cannot save held payment - rideId is empty');
        return;
      }

      // Don't save if no payment was held
      if (_heldAmount <= 0) {
        print('SAHAr: ⚠️ Cannot save held payment - held amount is 0 or negative');
        return;
      }

      // Use default driverId if not available (for scheduled rides, driver might not be assigned yet)
      String driverIdValue = driverId.value.isNotEmpty 
          ? driverId.value 
          : "00000000-0000-0000-0000-000000000000"; // Default GUID for pending assignment

      Map<String, dynamic> holdData = {
        "rideId": rideId,
        "userId": userId,
        "paymentIntentId": heldPaymentIntentId.value,
        "heldAmount": _heldAmount, // Use the actual amount that was held
        "driverId": driverIdValue,
        "paymentMethod": "Credit Card", // Stripe payments are credit card
      };

      print('SAHAr: 💾 Saving held payment to backend: $holdData');

      Response response = await _apiProvider.postData(
        ApiEndpoints.saveHeldPayment, // Backend endpoint
        holdData,
      );

      if (response.isOk) {
        print('SAHAr: ✅ Held payment saved successfully');
      } else {
        // Log but don't fail the ride - backend endpoint might not exist yet
        print('SAHAr: ⚠️ Failed to save held payment: ${response.statusText} (Status: ${response.statusCode})');
        print('SAHAr: ⚠️ Response body: ${response.body}');
        print('SAHAr: ⚠️ This is non-critical - ride can still proceed');

        if (response.statusCode == 404) {
          print('SAHAr: ⚠️ Backend endpoint ${ApiEndpoints.saveHeldPayment} not found. Please implement this endpoint.');
        }
      }
    } catch (e) {
      // Log but don't fail the ride
      print('SAHAr: ⚠️ Error saving held payment: $e');
      print('SAHAr: ⚠️ This is non-critical - ride can still proceed');
    }
  }

  /// STEP 2: When driver is found, save driver's Stripe ID
  void onDriverFound(Map<String, dynamic> driverData) {
    driverId.value = driverData['driverId'] ?? '';
    driverName.value = driverData['driverName'] ?? '';

    // IMPORTANT: Get driver's Stripe Connected Account ID
    driverStripeAccountId.value = driverData['driverStripeId'] ?? '';

    print('SAHAr: Driver found! ');
    print('SAHAr: Driver ID: ${driverId.value}');
    print('SAHAr: Driver Name: ${driverName.value}');
    print('SAHAr: Driver Stripe Account:  ${driverStripeAccountId. value}');

    if (driverStripeAccountId. value.isEmpty) {
      print('SAHAr: ⚠️ WARNING: Driver does not have Stripe account! ');
    }

    // CRITICAL FIX: Initialize chat background service immediately when driver is assigned
    try {
      SharedPrefsService.getUserId().then((userId) {
        if (userId != null && currentRideId.value.isNotEmpty) {
          Get.find<ChatBackgroundService>().updateRideInfo(
            rideId: currentRideId.value,
            driverId: driverId.value,
            driverName: driverName.value,
            currentUserId: userId,
            status: RideStatus.driverAssigned,
          );
          print('SAHAr: ✅ Chat background service initialized for ride ${currentRideId.value}');
        }
      });
    } catch (e) {
      print('SAHAr: ⚠️ Failed to initialize chat background service: $e');
    }
  }

  /// Fills [driverStripeAccountId] via `POST /api/Drivers/{driverId}` when it was lost (resume, held-payment restore).
  Future<void> _tryLoadDriverStripeAccountFromApi() async {
    if (driverStripeAccountId.value.trim().isNotEmpty) return;
    final id = driverId.value.trim();
    if (id.isEmpty) return;
    try {
      final r = await _apiProvider.postDataSilent(ApiEndpoints.getDriverById(id), {});
      if (!r.isOk || r.body is! Map<String, dynamic>) return;
      final m = r.body as Map<String, dynamic>;
      final acct = (m['stripeAccountId'] ?? m['StripeAccountId'])?.toString().trim() ?? '';
      if (acct.isNotEmpty) {
        driverStripeAccountId.value = acct;
        print('SAHAr: ✅ Driver Stripe account loaded from Drivers API');
      }
    } catch (e) {
      print('SAHAr: ⚠️ Drivers API lookup failed: $e');
    }
  }

  /// STEP 3: Complete payment when ride ends (capture + transfer)
  ///
  /// Returns whether fare capture / balance path completed successfully (tip-only flow may follow).
  Future<bool> _completePayment(
    double fareAfterBalance, {
    double tipAmount = 0.0,
    RidePaymentCompletionStyle completionStyle = RidePaymentCompletionStyle.standard,
  }) async {
    double totalAmountWithTip = fareAfterBalance + tipAmount;

    try {
      print('SAHAr: Starting _completePayment');
      print('SAHAr: 💰 Actual Fare (before balance): \$${actualFareBeforeBalance.value.toStringAsFixed(2)}');
      print('SAHAr: 💰 Fare after balance deduction: \$${fareAfterBalance.toStringAsFixed(2)}');
      print('SAHAr: 💰 Tip amount: \$${tipAmount.toStringAsFixed(2)}');
      print('SAHAr: 💰 Total to charge (fare + tip after balance): \$${totalAmountWithTip.toStringAsFixed(2)}');
      print('SAHAr: 💳 Held payment amount: \$${estimatedPrice.value.toStringAsFixed(2)}');
      isLoading.value = true;

      var userId = await SharedPrefsService.getUserId() ??
          AppConstants.defaultUserId;

      print('SAHAr: 📱 Retrieved user ID: $userId');

      double balanceUsed = actualFareBeforeBalance.value - fareAfterBalance;
      print('SAHAr: 💵 Balance Used: \$${balanceUsed.toStringAsFixed(2)}');

      // If balance covers the full fare (no card charge needed)
      if (totalAmountWithTip <= 0) {
        print('SAHAr: 💰 User balance covers the full fare - no card charge needed');

        // Cancel held payment if it exists
        if (heldPaymentIntentId.value.isNotEmpty &&
            heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
          print('SAHAr: Canceling held payment: ${heldPaymentIntentId.value}');
          await PaymentService.cancelHeldPayment(heldPaymentIntentId.value);
        }

        // Record as balance-paid ride (with actual fare amount)
        await _recordNoPaymentRide(fareAmount: actualFareBeforeBalance.value);

        // Close the payment dialog only if it is open (e.g. not when called from SignalR cancelled)
        if (Get.isDialogOpen == true) Get.back();

        _fareCaptureCompletedRideId = prevRideId.value;

        if (completionStyle == RidePaymentCompletionStyle.standard) {
          _showRideCompletedMessage(0, 0, paidFromBalance: true);
          await Future.delayed(Duration(milliseconds: 300));
          _showReviewDialog();
        } else {
          await _presentOptionalTipAfterFarePaid(actualFareBeforeBalance.value);
        }
        return true;
      }

      // Check if we have held payment for card charge
      if (heldPaymentIntentId.value.isEmpty ||
          heldPaymentIntentId.value == 'NO_PAYMENT_REQUIRED') {
        Get.snackbar('Error', 'No held payment found');
        print('SAHAr: ❌ No held payment intent available');
        return false;
      }

      await _tryLoadDriverStripeAccountFromApi();

      // Check driver's Stripe account (Stripe Connect destination for capture/transfer)
      if (driverStripeAccountId.value.isEmpty) {
        Get.snackbar(
          'Payment setup',
          'Driver payout account is not available. If this continues, contact support.',
        );
        print('SAHAr: ⚠️ Driver Stripe account missing!');
        return false;
      }

      // CRITICAL: Calculate the actual amount to capture
      // The held amount might be higher than what we need to charge
      int heldAmountCents = (_heldAmount * 100).round();
      int fareOnlyCents = (fareAfterBalance * 100).round();
      int tipAmountCents = (tipAmount * 100).round();
      int actualChargeWithTipCents = fareOnlyCents + tipAmountCents;

      print('SAHAr: 💳 Held Amount: ${heldAmountCents} cents (\$${(heldAmountCents/100).toStringAsFixed(2)})');
      print('SAHAr: 💳 Fare to Capture: ${fareOnlyCents} cents (\$${(fareOnlyCents/100).toStringAsFixed(2)})');
      print('SAHAr: 💳 Tip Amount: ${tipAmountCents} cents (\$${(tipAmountCents/100).toStringAsFixed(2)})');
      print('SAHAr: 💳 Total Needed: ${actualChargeWithTipCents} cents (\$${(actualChargeWithTipCents/100).toStringAsFixed(2)})');

      Map<String, String>? additionalPaymentInfo;
      int amountToCaptureFromHeld;
      int tipInHeldPayment;
      int additionalAmountNeeded = 0;

      // Check if total exceeds held amount
      if (actualChargeWithTipCents > heldAmountCents) {
        print('SAHAr: ⚠️ Total needed exceeds held amount - creating additional payment intent');
        additionalAmountNeeded = actualChargeWithTipCents - heldAmountCents;
        
        // Create additional payment intent for the excess amount
        additionalPaymentInfo = await _createAdditionalPaymentIntent(additionalAmountNeeded);
        
        if (additionalPaymentInfo == null || additionalPaymentInfo['chargeId'] == null || additionalPaymentInfo['chargeId']!.isEmpty) {
          print('SAHAr: ❌ Failed to process extra tip. Fallback to held amount.');
          Get.snackbar('Tip Info', 'Could not process extra tip. Only authorized amount will be charged.');

          // Fallback: Charge only what was held (fare + partial tip)
          amountToCaptureFromHeld = heldAmountCents;
          tipInHeldPayment = heldAmountCents - fareOnlyCents;
          if (tipInHeldPayment < 0) tipInHeldPayment = 0;
        } else {
          // Both payments successful
          amountToCaptureFromHeld = heldAmountCents;
          tipInHeldPayment = heldAmountCents - fareOnlyCents; // Tip that fits in held amount
          if (tipInHeldPayment < 0) tipInHeldPayment = 0;

          print('SAHAr: 💡 Capturing held payment: \$${(amountToCaptureFromHeld/100).toStringAsFixed(2)}');
          print('SAHAr: 💡 Additional payment created: ${additionalPaymentInfo['paymentIntentId']} for \$${(additionalAmountNeeded/100).toStringAsFixed(2)}');
        }
      } else {
        // Normal case: everything fits in held amount
        amountToCaptureFromHeld = actualChargeWithTipCents;
        tipInHeldPayment = tipAmountCents;
        print('SAHAr: ✅ Total charge fits within held amount');
      }

      // CAPTURE held payment and TRANSFER to driver
      final result = await PaymentService.captureAndTransferPayment(
        paymentIntentId: heldPaymentIntentId.value,
        driverStripeAccountId: driverStripeAccountId.value,
        totalAmountCents: amountToCaptureFromHeld,
        tipAmountCents: tipInHeldPayment,
        platformFeePercentOverride: adminPercentage.value > 0
            ? adminPercentage.value / 100.0
            : null,
      );

      if (result == null || result['success'] != true) {
        print('SAHAr: ❌ Failed to capture held payment');
        Get.snackbar('Payment Failed', 'Failed to complete payment. Please try again or contact support.');
        return false;
      }

      // If we have additional payment, transfer it to driver too
      Map<String, dynamic>? additionalResult;
      if (additionalPaymentInfo != null && additionalPaymentInfo['chargeId'] != null && additionalAmountNeeded > 0) {
        print('SAHAr: 💳 Processing additional payment for tip');
        
        String additionalChargeId = additionalPaymentInfo['chargeId']!;
        
        // Transfer additional tip amount to driver (100% of tip goes to driver)
        additionalResult = await PaymentService.transferAdditionalAmount(
          chargeId: additionalChargeId,
          driverStripeAccountId: driverStripeAccountId.value,
          amountCents: additionalAmountNeeded,
          tipAmountCents: additionalAmountNeeded, // Full additional amount is tip
        );
        
        if (additionalResult == null || additionalResult['success'] != true) {
          print('SAHAr: ⚠️ Warning: Additional payment captured but transfer failed');
        }
      }

      print('SAHAr: ✅ Payment completed successfully!');

      // Calculate total tip processed (from held + additional if any)
      double totalTipProcessed = (tipInHeldPayment / 100.0);
      if (additionalResult != null && additionalResult['success'] == true) {
        totalTipProcessed += (additionalAmountNeeded / 100.0);
      }

      // Save transaction to backend (including additional tip info if exists)
      bool transactionSaved = await _saveCompletedTransaction(
        result,
        userId,
        totalTipProcessed,
        balanceUsed: balanceUsed,
        additionalResult: additionalResult
      );

      // Call tip API AFTER successful payment (only if tip > 0)
      if (tipAmount > 0) {
        print('SAHAr: 📤 Submitting tip to API after successful payment');
        await _submitTip(tipAmount, fareAfterBalance, totalAmountWithTip);
      }

      // Reset tip amount after successful payment completion
      selectedTipAmount.value = 0.0;

      // Close the payment dialog now that transaction is saved (only if open)
      if (transactionSaved && Get.isDialogOpen == true) {
        Get.back();
      }

      _fareCaptureCompletedRideId = prevRideId.value;

      if (completionStyle == RidePaymentCompletionStyle.autoFareThenOptionalTip &&
          tipAmount <= 0) {
        await _presentOptionalTipAfterFarePaid(fareAfterBalance);
        return true;
      }

      // Show success message
      double driverAmount = result['driver_amount'] / 100;
      double platformFee = result['platform_fee'] / 100;

      // Add additional driver amount if additional payment was processed
      if (additionalResult != null && additionalResult['success'] == true) {
        driverAmount += (additionalAmountNeeded / 100.0); // Full tip goes to driver
      }

      _showRideCompletedMessage(driverAmount, platformFee, balanceUsed: balanceUsed);

      // Wait a moment to ensure payment dialog is fully closed before showing review dialog
      await Future.delayed(Duration(milliseconds: 300));

      // Show review dialog
      _showReviewDialog();

      // Clear payment data
      _clearPaymentData();
      return true;
    } catch (e) {
      print('SAHAr: ❌ Error in _completePayment: $e');
      Get.snackbar('Payment Error', 'Failed to process payment: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// After fare is captured (FCM / resume auto-flow), only ask for an optional tip, then review.
  Future<void> _presentOptionalTipAfterFarePaid(double finalFare) async {
    final safeFare = finalFare < 0 ? 0.0 : finalFare;
    final driverLabel =
        driverName.value.isNotEmpty ? driverName.value : 'your driver';
    final RxDouble selectedTip = 0.0.obs;
    final tipOptions = AppConstants.tipPercentages;

    await Get.dialog<void>(
      PopScope(
        canPop: true,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: MColor.primaryNavy, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fare paid',
                  style: TextStyle(
                    color: MColor.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: Get.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip total: \$${safeFare.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional tip for $driverLabel?',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Text('Quick amounts', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tipOptions
                          .map(
                            (t) => ChoiceChip(
                              label: Text('\$${t.toStringAsFixed(0)}'),
                              selected: selectedTip.value == t,
                              onSelected: (sel) {
                                if (sel) selectedTip.value = t;
                              },
                              selectedColor: MColor.primaryNavy.withValues(alpha: 0.25),
                            ),
                          )
                          .toList(),
                    )),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Custom tip',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) {
                    final c = double.tryParse(v);
                    if (c != null && c >= 0) selectedTip.value = c;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                _clearPaymentData();
                Future.delayed(const Duration(milliseconds: 200), _showReviewDialog);
              },
              child: Text('Skip', style: TextStyle(color: MColor.primaryNavy)),
            ),
            Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColor.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final tip = selectedTip.value;
                    Get.back();
                    if (tip > 0) {
                      await _chargePostFareTip(tip, safeFare);
                    } else {
                      _clearPaymentData();
                      Future.delayed(const Duration(milliseconds: 200), _showReviewDialog);
                    }
                  },
                  child: Text(selectedTip.value > 0 ? 'Pay tip' : 'Done'),
                )),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Charge tip after the held payment was already captured for the fare only.
  Future<void> _chargePostFareTip(double tipAmount, double finalFare) async {
    if (tipAmount <= 0) return;
    try {
      isLoading.value = true;
      await _tryLoadDriverStripeAccountFromApi();
      if (driverStripeAccountId.value.isEmpty) {
        Get.snackbar(
          'Tip',
          'Driver payout is unavailable. Tip could not be charged.',
        );
        await _submitTip(tipAmount, finalFare, finalFare + tipAmount);
        _clearPaymentData();
        Future.delayed(const Duration(milliseconds: 200), _showReviewDialog);
        return;
      }

      final cents = (tipAmount * 100).round();
      final info = await _createAdditionalPaymentIntent(cents);
      if (info == null ||
          info['chargeId'] == null ||
          info['chargeId']!.isEmpty) {
        Get.snackbar('Tip', 'Could not process tip payment.');
        _clearPaymentData();
        Future.delayed(const Duration(milliseconds: 200), _showReviewDialog);
        return;
      }

      final transfer = await PaymentService.transferAdditionalAmount(
        chargeId: info['chargeId']!,
        driverStripeAccountId: driverStripeAccountId.value,
        amountCents: cents,
        tipAmountCents: cents,
      );

      if (transfer == null || transfer['success'] != true) {
        print('SAHAr: ⚠️ Tip charge ok but transfer failed');
      }

      await _submitTip(tipAmount, finalFare, finalFare + tipAmount);
    } catch (e) {
      print('SAHAr: _chargePostFareTip error: $e');
      Get.snackbar('Tip', 'Failed to process tip: $e');
    } finally {
      isLoading.value = false;
      _clearPaymentData();
      Future.delayed(const Duration(milliseconds: 200), _showReviewDialog);
    }
  }

  /// FCM (or cold start) when SignalR missed trip completion: capture fare automatically, then tip-only UI.
  ///
  /// Expects [data] keys: `rideId`, and `finalFare` / `fareFinal` / `totalFare` when possible.
  Future<void> handleRideCompletedFromPush(Map<String, dynamic> data) async {
    try {
      if (!await SharedPrefsService.isUserLoggedIn()) return;

      final rideId = (data['rideId'] ?? '').toString().trim();
      if (rideId.isEmpty) return;

      if (_fareCaptureCompletedRideId.isNotEmpty &&
          _fareCaptureCompletedRideId == rideId) {
        print('SAHAr: FCM ride_completed ignored — already captured for $rideId');
        return;
      }

      final srConnected = Get.isRegistered<SignalRService>() &&
          Get.find<SignalRService>().connectionStatus.value ==
              SignalRConnectionStatus.connected;
      if (srConnected) {
        print(
            'SAHAr: FCM ride_completed ignored for auto-pay — SignalR connected (in-app completion handles UI)');
        return;
      }

      if (currentRideId.value.isNotEmpty && currentRideId.value != rideId) {
        print(
            'SAHAr: FCM ride_completed rideId mismatch (current=${currentRideId.value} fcm=$rideId)');
        return;
      }

      double finalFare = _parseFareNumber(
          data['finalFare'] ?? data['fareFinal'] ?? data['totalFare']);
      if (finalFare <= 0) {
        final userId = await SharedPrefsService.getUserId();
        if (userId == null || userId.isEmpty) return;
        final r = await _apiProvider.postDataSilent(
          '${ApiEndpoints.getUserLastRide}?userId=$userId',
          {},
        );
        if (r.isOk && r.body is Map) {
          final m = _asStringKeyedMap(r.body);
          if (m != null && (m['rideId']?.toString() ?? '') == rideId) {
            finalFare = _parseFareNumber(m['fareFinal']);
            if (finalFare <= 0) {
              finalFare = _parseFareNumber(m['fareEstimate']);
            }
          }
        }
      }
      if (finalFare <= 0) {
        print('SAHAr: FCM ride_completed — could not resolve finalFare');
        return;
      }

      if (heldPaymentIntentId.value.isEmpty ||
          heldPaymentIntentId.value == 'NO_PAYMENT_REQUIRED') {
        print(
            'SAHAr: FCM ride_completed — no held PI in memory; user may need resume flow');
        return;
      }

      if (currentRideId.value.isEmpty) {
        currentRideId.value = rideId;
      }
      prevRideId.value = rideId;
      actualFareBeforeBalance.value = finalFare;
      rideStatus.value = RideStatus.tripCompleted;

      if (!(await _waitForDialogSlot())) return;

      final ok = await _completePayment(
        finalFare,
        tipAmount: 0,
        completionStyle: RidePaymentCompletionStyle.autoFareThenOptionalTip,
      );
      if (!ok) {
        Get.snackbar(
          'Payment',
          'Could not complete payment automatically. Open the app to finish.',
        );
      }
    } catch (e) {
      print('SAHAr: handleRideCompletedFromPush error: $e');
    }
  }

  /// Save completed transaction to backend
  Future<bool> _saveCompletedTransaction(
      Map<String, dynamic> result,
      String userId,
      double tipAmount,
      {double balanceUsed = 0.0,
      Map<String, dynamic>? additionalResult}
      ) async {
    try {
      Map<String, dynamic> paymentData = {
        "rideId": prevRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "paymentIntentId": result['payment_intent_id'],
        "transferId": result['transfer_id'],
        "totalAmount": result['total_amount'] / 100, // Convert to dollars
        "rideAmount": actualFareBeforeBalance.value, // Actual fare before balance
        "balanceUsed": balanceUsed, // Amount paid from balance
        "cardCharged": result['total_amount'] / 100, // Amount charged to card
        "tipAmount": tipAmount,
        "driverAmount": result['driver_amount'] / 100,
        "platformFee": result['platform_fee'] / 100,
        "adminPercentage": adminPercentage.value,
        "status": "completed",
        "completedAt": DateTime.now().toIso8601String(),
      };

      // Add additional tip transaction info if it exists
      if (additionalResult != null && additionalResult['success'] == true) {
        paymentData['additionalTipChargeId'] = additionalResult['charge_id'];
        paymentData['additionalTipTransferId'] = additionalResult['transfer_id'];
        paymentData['additionalTipAmount'] = additionalResult['tip_amount'] / 100;
      }

      print('SAHAr: Saving completed transaction: $paymentData');

      Response response = await _apiProvider.postData(
        ApiEndpoints.completeTransaction, // Backend endpoint
        paymentData,
      );

      if (response.isOk) {
        print('SAHAr: ✅ Transaction saved successfully');
        return true;
      } else {
        print('SAHAr: ⚠️ Failed to save transaction: ${response.statusText}');
        return false;
      }
    } catch (e) {
      print('SAHAr: ❌ Error saving transaction: $e');
      return false;
    }
  }

  /// Record ride with no payment (for free rides or balance-paid rides)
  Future<void> _recordNoPaymentRide({double fareAmount = 0.0}) async {
    try {
      var userId = await SharedPrefsService. getUserId() ??
          AppConstants.defaultUserId;

      Map<String, dynamic> data = {
        "rideId": prevRideId.value,
        "userId": userId,
        "driverId": driverId.value,
        "amount": fareAmount, // Record actual fare (paid from balance)
        "status": fareAmount > 0 ? "completed_balance_paid" : "completed_no_payment",
        "completedAt": DateTime.now().toIso8601String(),
      };

      await _apiProvider.postData(ApiEndpoints.completeTransaction, data);
      print('SAHAr: ${fareAmount > 0 ? "Balance-paid" : "No-payment"} ride recorded (Amount: \$${fareAmount.toStringAsFixed(2)})');
    } catch (e) {
      print('SAHAr: Error recording no-payment ride:  $e');
    }
  }

  /// Show ride completed message
  void _showRideCompletedMessage(double driverAmount, double platformFee, {bool paidFromBalance = false, double balanceUsed = 0.0}) {
    String message;

    if (driverAmount == 0 && platformFee == 0) {
      if (paidFromBalance && actualFareBeforeBalance.value > 0) {
        message = "Ride completed successfully!\n"
            "Fare of \$${actualFareBeforeBalance.value.toStringAsFixed(2)} paid from your balance.";
      } else {
        message = "Ride completed successfully!\nNo payment required.";
      }
    } else {
      message = "Payment completed successfully!\n"
          "Total Fare: \$${actualFareBeforeBalance.value.toStringAsFixed(2)}\n";
    }

    Get.snackbar(
      driverAmount == 0 ? 'Ride Completed!' : 'Payment Successful!',
      message,
      backgroundColor: MColor.primaryNavy.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
    );
  }

  /// Cancel held payment (if ride is cancelled)
  Future<void> cancelRideAndRefund() async {
    try {
      if (heldPaymentIntentId.value.isNotEmpty &&
          heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {

        print('SAHAr:  Cancelling held payment...');

        bool cancelled = await PaymentService.cancelHeldPayment(
            heldPaymentIntentId.value
        );

        if (cancelled) {
          print('SAHAr: ✅ Payment hold cancelled successfully');

          // Update backend
          await _updateCancelledRideInBackend();

          Get.snackbar(
            'Ride Cancelled',
            'Payment hold has been released. No charges applied.',
            backgroundColor: Colors.orange. withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        } else {
          print('SAHAr: ❌ Failed to cancel payment hold');
        }

        _clearPaymentData();
      }
    } catch (e) {
      print('SAHAr: Error cancelling ride: $e');
    }
  }

  /// Cancel ride - releases Stripe payment hold and clears everything back to starting point
  Future<void> cancelRide() async {
    try {
      isLoading.value = true;

      print('SAHAr: Cancelling ride - releasing payment hold and clearing booking');

      // Show loading dialog with animation
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false, // Prevent closing during cancellation
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, fadeValue, child) {
                return Opacity(
                  opacity: fadeValue,
                  child: Transform.scale(
                    scale: 0.9 + (fadeValue * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated loading indicator
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (value * 0.2),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withValues(alpha: 0.1),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                      Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Animated text
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - value)),
                                  child: Text(
                                    'Cancelling ride...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Small delay for animation to show
      await Future.delayed(const Duration(milliseconds: 500));

      // Release Stripe payment hold if payment was held
      if (heldPaymentIntentId.value.isNotEmpty && 
          heldPaymentIntentId.value != 'NO_PAYMENT_REQUIRED') {
        print('SAHAr: Releasing Stripe payment hold...');
        await PaymentService.cancelHeldPayment(heldPaymentIntentId.value);
        print('SAHAr: ✅ Payment hold released');
      }

      // Clear payment data
      _clearPaymentData();

      // Clear everything back to starting point
      clearBooking();

      // Close loading dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Show success animation
      await Future.delayed(const Duration(milliseconds: 200));
      
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ride Cancelled',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Payment hold released',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        barrierDismissible: true,
      );

      // Auto-close success dialog after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (Get.isDialogOpen == true) {
        Get.back();
      }

    } catch (e) {
      print('SAHAr: Error cancelling ride: $e');
      
      // Close loading dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Show error with animation
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.9 + (value * 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error cancelling ride: $e',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        barrierDismissible: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update cancelled ride in backend
  Future<void> _updateCancelledRideInBackend() async {
    try {
      await _apiProvider.postData(
        ApiEndpoints.cancelRide,
        {
          "rideId": prevRideId. value,
          "paymentIntentId": heldPaymentIntentId.value,
          "status": "cancelled",
          "cancelledAt": DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('SAHAr: Error updating cancelled ride: $e');
    }
  }

  /// Clear payment data (public for use from SignalR cancelled flow).
  void clearPaymentData() {
    _clearPaymentData();
  }

  /// Clear payment data (internal).
  void _clearPaymentData() {
    heldPaymentIntentId.value = '';
    driverStripeAccountId.value = '';
    _heldAmount = 0.0;
    selectedTipAmount.value = 0.0;
    _paymentDialogData = null;
    SharedPrefsService.clearPendingPaymentState();
    print('SAHAr: Payment data cleared');
  }

  Future<void> _persistPendingPaymentState() async {
    if (_paymentDialogData == null) return;
    try {
      final map = <String, dynamic>{
        ..._paymentDialogData!,
        'heldPaymentIntentId': heldPaymentIntentId.value,
        'heldAmount': _heldAmount,
        'driverStripeAccountId': driverStripeAccountId.value,
        'driverId': driverId.value,
        'driverName': driverName.value,
        'actualFareBeforeBalance': actualFareBeforeBalance.value,
        'adminPercentage': adminPercentage.value,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await SharedPrefsService.savePendingPaymentState(jsonEncode(map));
    } catch (e) {
      print('SAHAr: Failed to persist pending payment: $e');
    }
  }

  /// GetConnect may return `Map<dynamic, dynamic>`; normalize so resume / payment logic always runs.
  Map<String, dynamic>? _asStringKeyedMap(dynamic body) {
    if (body == null) return null;
    if (body is Map<String, dynamic>) return body;
    if (body is Map) {
      try {
        return Map<String, dynamic>.from(
          body.map((k, v) => MapEntry(k.toString(), v)),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Called after login when the map home is shown (Uber-style resume + held-payment).
  Future<void> checkLastRideOnHomeOpen() async {
    if (_lastRideResumeCheckDone) return;
    try {
      if (!await SharedPrefsService.isUserLoggedIn()) return;

      // This check is meant to run on the MainMap (HomeScreen). If user navigated away,
      // skip any resume/payment UI so it doesn't appear on other pages (e.g. RideBookingPage).
      if (Get.currentRoute != '/mainMap') return;

      final int seq = ++_lastRideResumeCheckSeq;
      final userId = await SharedPrefsService.getUserId();
      if (userId == null || userId.isEmpty) return;

      final response = await _apiProvider.postDataSilent(
        '${ApiEndpoints.getUserLastRide}?userId=$userId',
        {},
      );

      // If another check started, or user navigated away while awaiting, ignore this result.
      if (seq != _lastRideResumeCheckSeq) return;
      if (Get.currentRoute != '/mainMap') return;

      if (!response.isOk) {
        print('SAHAr: get-user-last-ride failed: ${response.statusCode} ${response.statusText}');
        return;
      }

      final body = response.body;
      if (body == null) {
        await SharedPrefsService.clearPendingPaymentState();
        _lastRideResumeCheckDone = true;
        return;
      }

      final map = _asStringKeyedMap(body);
      if (map == null) {
        print('SAHAr: get-user-last-ride: body is not a JSON object: ${body.runtimeType}');
        _lastRideResumeCheckDone = true;
        return;
      }

      final status = (map['status'] ?? '').toString();
      final normalized = status.trim().toLowerCase();
      final rideIdStr = (map['rideId'] ?? '').toString().trim();

      if (normalized == 'cancelled') {
        await SharedPrefsService.clearPendingPaymentState();
        _lastRideResumeCheckDone = true;
        return;
      }

      if (normalized == 'completed') {
        final paymentStatus = (map['paymentStatus'] ?? '').toString().trim().toLowerCase();
        // Backend may send `paymentIntentId` and/or `paymentToken` (often identical).
        // Treat `paymentToken` as a fallback so resume/payment UI works across versions.
        final paymentIntentId = (map['paymentIntentId'] ?? map['paymentToken'] ?? '')
            .toString()
            .trim();
        // Resume trip is only for non-completed rides.
        // Completed + (held or pending) should surface the payment UI.
        //
        // Some backends send `paymentStatus: Pending` and omit `paymentIntentId` from this endpoint,
        // but we can still restore from locally persisted pending payment state (or fetch details by rideId).
        final prefsJson = await SharedPrefsService.getPendingPaymentState();
        bool hasPrefsForRide = false;
        if (prefsJson != null && prefsJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(prefsJson);
            if (decoded is Map) {
              final rideIdFromPrefs = (decoded['rideId'] ?? '').toString().trim();
              hasPrefsForRide = rideIdFromPrefs.isNotEmpty && rideIdFromPrefs == rideIdStr;
            }
          } catch (_) {}
        }

        final needsPaymentUi = paymentStatus == 'held' || paymentStatus == 'pending';

        if (needsPaymentUi) {
          print(
            'SAHAr: Last ride Completed with pending/held payment — showing payment UI '
            '(status="$paymentStatus" piLen=${paymentIntentId.length} prefs=$hasPrefsForRide)',
          );
          await Future.delayed(const Duration(milliseconds: 400));
          if (seq != _lastRideResumeCheckSeq) return;
          if (Get.currentRoute != '/mainMap') return;
          if (!(await _waitForDialogSlot())) {
            return;
          }
          await _restoreCompletedHeldPaymentFromLastRide(map);
        } else {
          print(
            'SAHAr: Last ride is Completed — no resume popup. '
            'Payment UI only when paymentStatus is held/pending; '
            'got paymentStatus="$paymentStatus" intentEmpty=${paymentIntentId.isEmpty} prefsForRide=$hasPrefsForRide',
          );
          // Only clear persisted state when backend clearly indicates there's nothing to pay.
          if (!needsPaymentUi) {
            await SharedPrefsService.clearPendingPaymentState();
          }
        }
        _lastRideResumeCheckDone = true;
        return;
      }

      // Unknown / missing status: still offer resume if we have a ride id (backend quirks).
      if (normalized.isEmpty && rideIdStr.isEmpty) {
        _lastRideResumeCheckDone = true;
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (seq != _lastRideResumeCheckSeq) return;
      if (Get.currentRoute != '/mainMap') return;
      if (!(await _waitForDialogSlot())) {
        return;
      }
      _showResumeRideDialog(map);
      _lastRideResumeCheckDone = true;
    } catch (e) {
      print('SAHAr: checkLastRideOnHomeOpen error: $e');
    }
  }

  /// Waits until no GetX dialog is covering the screen (or times out). Returns false if still blocked.
  Future<bool> _waitForDialogSlot() async {
    if (Get.isDialogOpen != true) return true;
    for (var i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (Get.isDialogOpen != true) return true;
    }
    print('SAHAr: resume/payment UI skipped — another dialog stayed open');
    return false;
  }

  void _showResumeRideDialog(Map<String, dynamic> lastRide) {
    final status = (lastRide['status'] ?? '').toString();
    final pickup = (lastRide['pickupLocation'] ?? '').toString();
    final dropoff = (lastRide['dropOffLocation'] ?? '').toString();

    Get.dialog(
      barrierDismissible: false,
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_car_rounded, color: MColor.primaryNavy, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resume your trip?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MColor.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You have a ride in progress. Continue where you left off?',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              ),
              if (pickup.isNotEmpty || dropoff.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (pickup.isNotEmpty)
                  Text('Pickup: $pickup', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                if (dropoff.isNotEmpty)
                  Text('Drop-off: $dropoff', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
              ],
              if (status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Status: $status',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColor.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Get.back();
                        await _resumeActiveRideFromLastRideMap(lastRide);
                      },
                      child: const Text('Resume'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resumeActiveRideFromLastRideMap(Map<String, dynamic> lastRide) async {
    final rideId = (lastRide['rideId'] ?? '').toString();
    if (rideId.isEmpty) return;

    final response = await _apiProvider.postDataSilent('/api/Ride/$rideId', {});
    Map<String, dynamic>? detail;
    if (response.isOk && response.body is Map<String, dynamic>) {
      detail = response.body as Map<String, dynamic>;
    }

    _hydrateLocationsFromLastRide(lastRide);
    currentRideId.value = rideId;
    prevRideId.value = rideId;
    isRideBooked.value = true;

    if (detail != null) {
      driverId.value = (detail['driverId'] ?? lastRide['driverId'] ?? '').toString();
      driverName.value = (detail['driverName'] ?? '').toString();
      final vehicle = (detail['vehicle'] ?? '').toString();
      final vehicleColor = (detail['vehicleColor'] ?? '').toString();
      this.vehicle.value = vehicle;
      this.vehicleColor.value = vehicleColor;
      rating.value = 0.0;
      driverPhone.value = '';
      estimatedPrice.value = _parseFareNumber(detail['fareEstimate'] ?? lastRide['fareEstimate']);
      final fareFinal = (detail['fareFinal'] != null) ? _parseFareNumber(detail['fareFinal']) : 0.0;
      if (fareFinal > 0) estimatedPrice.value = fareFinal;
    } else {
      driverId.value = (lastRide['driverId'] ?? '').toString();
      driverName.value = '';
      estimatedPrice.value = _parseFareNumber(lastRide['fareEstimate'] ?? lastRide['fareFinal']);
    }

    final paymentIntent = (lastRide['paymentIntentId'] ?? '').toString();
    if (paymentIntent.isNotEmpty) {
      heldPaymentIntentId.value = paymentIntent;
    }

    final stripe = (detail?['driverPayment'] ?? detail?['driverStripeAccount'])?.toString() ?? '';
    if (stripe.isNotEmpty && stripe.startsWith('acct_')) {
      driverStripeAccountId.value = stripe;
    }
    await _tryLoadDriverStripeAccountFromApi();

    rideStatus.value = _mapServerRideStatusToEnum(
      (detail?['status'] ?? lastRide['status'] ?? '').toString(),
    );

    if (currentRideId.value.isNotEmpty) {
      signalRService.subscribeToRide(currentRideId.value);
    }

    try {
      final uid = await SharedPrefsService.getUserId();
      if (uid != null && currentRideId.value.isNotEmpty) {
        Get.find<ChatBackgroundService>().updateRideInfo(
          rideId: currentRideId.value,
          driverId: driverId.value,
          driverName: driverName.value,
          currentUserId: uid,
          status: rideStatus.value,
        );
      }
    } catch (_) {}

    if (pickupLocation.value != null && dropoffLocation.value != null) {
      await _mapService.createRouteMarkersAndPolylines(
        pickupLocation: pickupLocation.value,
        dropoffLocation: dropoffLocation.value,
        additionalStops: additionalStops,
      );
    }

    Get.snackbar(
      'Ride resumed',
      'Your trip is active again.',
      backgroundColor: MColor.primaryNavy.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void _hydrateLocationsFromLastRide(Map<String, dynamic> lastRide) {
    final pickupAddr = (lastRide['pickupLocation'] ?? '').toString();
    final dropAddr = (lastRide['dropOffLocation'] ?? '').toString();
    final pickupLat = _parseFareNumber(lastRide['pickupLat']);
    final pickupLng = _parseFareNumber(lastRide['pickupLng']);
    final dropLat = _parseFareNumber(lastRide['dropOffLat']);
    final dropLng = _parseFareNumber(lastRide['dropOffLng']);

    pickupLocation.value = LocationData(
      address: pickupAddr,
      latitude: pickupLat,
      longitude: pickupLng,
      stopOrder: 0,
    );
    pickupController.text = pickupAddr;
    dropoffLocation.value = LocationData(
      address: dropAddr,
      latitude: dropLat,
      longitude: dropLng,
      stopOrder: 1,
    );
    dropoffController.text = dropAddr;

    additionalStops.clear();
    for (var c in stopControllers) {
      c.dispose();
    }
    stopControllers.clear();

    final stops = lastRide['rideStops'];
    if (stops is List && stops.length > 2) {
      final raw = <Map<String, dynamic>>[];
      for (final e in stops) {
        if (e is Map<String, dynamic>) {
          raw.add(e);
        } else if (e is Map) {
          raw.add(Map<String, dynamic>.from(e));
        }
      }
      raw.sort((a, b) => _parseFareNumber(a['stopOrder']).compareTo(_parseFareNumber(b['stopOrder'])));

      for (var i = 1; i < raw.length - 1; i++) {
        final s = raw[i];
        final addr = (s['location'] ?? '').toString();
        final lat = _parseFareNumber(s['latitude']);
        final lng = _parseFareNumber(s['longitude']);
        final tc = TextEditingController(text: addr);
        stopControllers.add(tc);
        additionalStops.add(
          LocationData(address: addr, latitude: lat, longitude: lng, stopOrder: i),
        );
      }
    }
  }

  RideStatus _mapServerRideStatusToEnum(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return RideStatus.waiting;
      case 'waiting':
        return RideStatus.waiting;
      case 'driver assigned':
        return RideStatus.driverAssigned;
      case 'arrived':
        return RideStatus.driverArrived;
      case 'in-progress':
      case 'inprogress':
      case 'ongoing':
        return RideStatus.tripStarted;
      case 'completed':
        return RideStatus.tripCompleted;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.driverAssigned;
    }
  }

  Future<void> _restoreCompletedHeldPaymentFromLastRide(Map<String, dynamic> lastRide) async {
    final rideId = (lastRide['rideId'] ?? '').toString();
    if (rideId.isEmpty) return;

    final prefsJson = await SharedPrefsService.getPendingPaymentState();
    Map<String, dynamic>? prefsMap;
    if (prefsJson != null && prefsJson.isNotEmpty) {
      try {
        prefsMap = jsonDecode(prefsJson) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (prefsMap != null && (prefsMap['rideId']?.toString() ?? '') != rideId) {
      prefsMap = null;
    }

    final fareFinal = _parseFareNumber(lastRide['fareFinal']);
    final fareEstimate = _parseFareNumber(lastRide['fareEstimate']);
    final distance = _parseFareNumber(lastRide['distance']);

    if (prefsMap != null) {
      heldPaymentIntentId.value =
          prefsMap['heldPaymentIntentId']?.toString() ??
              (lastRide['paymentIntentId'] ?? lastRide['paymentToken'] ?? '').toString();
      driverStripeAccountId.value = prefsMap['driverStripeAccountId']?.toString() ?? '';
      driverId.value = prefsMap['driverId']?.toString() ?? (lastRide['driverId'] ?? '').toString();
      driverName.value = prefsMap['driverName']?.toString() ?? '';
      _heldAmount = _parseFareNumber(prefsMap['heldAmount']);
      actualFareBeforeBalance.value = _parseFareNumber(prefsMap['actualFareBeforeBalance']);
      if (actualFareBeforeBalance.value <= 0) {
        actualFareBeforeBalance.value = fareFinal > 0 ? fareFinal : fareEstimate;
      }
      adminPercentage.value = _parseFareNumber(prefsMap['adminPercentage']);
      final origHeld = _parseFareNumber(prefsMap['originalHeldAmount']);
      if (origHeld > 0) {
        estimatedPrice.value = origHeld;
      }
    } else {
      heldPaymentIntentId.value =
          (lastRide['paymentIntentId'] ?? lastRide['paymentToken'] ?? '').toString();
      driverId.value = (lastRide['driverId'] ?? '').toString();
      driverName.value = '';
      _heldAmount = fareEstimate > 0 ? fareEstimate : fareFinal;
      actualFareBeforeBalance.value = fareFinal > 0 ? fareFinal : fareEstimate;
      final r = await _apiProvider.postDataSilent('/api/Ride/$rideId', {});
      if (r.isOk && r.body is Map<String, dynamic>) {
        final m = r.body as Map<String, dynamic>;
        driverName.value = m['driverName']?.toString() ?? '';
        final stripe = (m['driverPayment'] ?? '').toString();
        if (stripe.startsWith('acct_')) {
          driverStripeAccountId.value = stripe;
        }
        // Some endpoints omit paymentIntentId — try to recover it from the ride details.
        if (heldPaymentIntentId.value.trim().isEmpty) {
          final pi = (m['paymentIntentId'] ??
                  m['PaymentIntentId'] ??
                  m['paymentToken'] ??
                  m['PaymentToken'] ??
                  '')
              .toString()
              .trim();
          if (pi.isNotEmpty) {
            heldPaymentIntentId.value = pi;
          }
        }
      }
    }

    if (fareFinal > 0) {
      actualFareBeforeBalance.value = _roundMoney2(fareFinal);
    } else if (actualFareBeforeBalance.value > 0) {
      actualFareBeforeBalance.value = _roundMoney2(actualFareBeforeBalance.value);
    }

    // `_showPaymentDialog` reads `estimatedPrice` as the pre-auth hold before replacing with final fare.
    if (estimatedPrice.value <= 0) {
      estimatedPrice.value = _heldAmount > 0 ? _heldAmount : actualFareBeforeBalance.value;
    }

    final apiFinal = fareFinal > 0 ? _roundMoney2(fareFinal) : _roundMoney2(fareEstimate);
    final apiQuoted = fareEstimate > 0 ? _roundMoney2(fareEstimate) : _roundMoney2(fareFinal);
    _reconcileHeldAmountWhenQuoteMatchesFinal(
      _roundMoney2(apiFinal),
      _roundMoney2(apiQuoted),
    );

    rideStatus.value = RideStatus.tripCompleted;
    isRideBooked.value = true;
    currentRideId.value = rideId;
    prevRideId.value = rideId;

    final tripData = <String, dynamic>{
      'rideId': rideId,
      'finalFare': actualFareBeforeBalance.value,
      'distance': distance,
      'totalWaitingTime': (lastRide['totalWaitingTime'] ?? '').toString(),
      'rideStartTime': (lastRide['rideStartTime'] ?? '').toString(),
      'rideEndTime': (lastRide['rideEndTime'] ?? '').toString(),
      'status': 'Completed',
      'tip': lastRide['tip'] ?? 'No Tip',
    };

    await _tryLoadDriverStripeAccountFromApi();

    final ok = await _completePayment(
      actualFareBeforeBalance.value,
      tipAmount: 0,
      completionStyle: RidePaymentCompletionStyle.autoFareThenOptionalTip,
    );
    if (!ok) {
      await _showPaymentDialog(tripData);
    }
  }

  /// Create additional payment intent for excess tip amount
  /// Returns map with 'paymentIntentId' and 'chargeId'
  Future<Map<String, String>?> _createAdditionalPaymentIntent(int amountCents) async {
    try {
      print('SAHAr: Creating additional payment intent for ${amountCents} cents');
      
      var userName = await SharedPrefsService.getUserFullName() ?? AppConstants.defaultUserName;
      
      // Create payment intent with automatic capture for additional amount
      Map<String, dynamic>? paymentIntent = await PaymentService.createPaymentIntentWithImmediateCapture(
        amount: amountCents.toString(),
        currency: 'cad',
        description: 'Additional tip payment',
      );
      
      if (paymentIntent == null) {
        print('SAHAr: ❌ Failed to create additional payment intent');
        return null;
      }
      
      String paymentIntentId = paymentIntent['id'];
      
      // Show Stripe payment sheet to authorize and capture additional payment
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: userName,
        ),
      );
      
      await Stripe.instance.presentPaymentSheet();
      print('SAHAr: ✅ Additional payment captured');
      
      // Retrieve payment intent to get charge ID after capture
      String? chargeId = await _getChargeIdFromPaymentIntent(paymentIntentId);
      
      if (chargeId == null) {
        print('SAHAr: ⚠️ Warning: Could not get charge ID from additional payment intent');
        // Still return payment intent ID, we can try to get charge ID later
      }
      
      return {
        'paymentIntentId': paymentIntentId,
        'chargeId': chargeId ?? '',
      };
    } on StripeException catch (e) {
      print('SAHAr: ❌ StripeException in additional payment: ${e.error.localizedMessage}');
      Get.snackbar('Payment Cancelled', 'Additional tip payment was cancelled');
      return null;
    } catch (e) {
      print('SAHAr: ❌ Error creating additional payment intent: $e');
      Get.snackbar('Payment Error', 'Failed to process additional tip payment: $e');
      return null;
    }
  }

  /// Get charge ID from payment intent
  Future<String?> _getChargeIdFromPaymentIntent(String paymentIntentId) async {
    try {
      final retrievedPI = await PaymentService.retrievePaymentIntent(paymentIntentId);
      if (retrievedPI != null) {
        if (retrievedPI['latest_charge'] != null) {
          return retrievedPI['latest_charge'];
        } else if (retrievedPI['charges'] != null &&
                   retrievedPI['charges']['data'] != null &&
                   retrievedPI['charges']['data'].isNotEmpty) {
          return retrievedPI['charges']['data'][0]['id'];
        }
      }
      return null;
    } catch (e) {
      print('SAHAr: ❌ Error getting charge ID: $e');
      return null;
    }
  }
 

  // Getters that delegate to services
  List<AutocompletePrediction> get searchSuggestions => _searchService.searchSuggestions;
  bool get isSearching => _searchService.isSearching.value;
  String get activeSearchField => _searchService.activeSearchField.value;
  Set<Marker> get markers => _mapService.markers;
  Set<Polyline> get polylines => _mapService.polylines;
  String get routeDistance => _mapService.routeDistance.value;
  String get routeDuration => _mapService.routeDuration.value;
  bool get isLoadingRoute => _mapService.isLoadingRoute.value;
}
