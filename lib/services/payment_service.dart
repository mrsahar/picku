import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static String get secretKey => dotenv. env['STRIPE_SECRET_KEY'] ??  '';
  static String get publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ??  '';

  // Admin platform fee percentage (e.g., 20%)
  static const double platformFeePercent = 0.20;

  /// Step 1: Create Payment Intent with HOLD (capture_method:  manual)
  /// This will authorize/hold the amount but NOT capture it yet
  static Future<Map<String, dynamic>?> createPaymentIntentWithHold({
    required String amount, // amount in cents
    required String currency,
    String? customerId,
    String? description,
  }) async {
    try {
      print('Creating payment intent with HOLD (manual capture)');
      print('Amount: $amount cents, Currency: $currency');

      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

      final headers = {
        'Authorization': 'Bearer $secretKey',
        'Content-Type':  'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-10-16',
      };

      // KEY CHANGE: capture_method = manual (this HOLDS the payment)
      final Map<String, String> requestBody = {
        'amount': amount,
        'currency': currency. toLowerCase(),
        'capture_method': 'manual', // <-- THIS IS THE KEY FOR HOLDING
        'automatic_payment_methods[enabled]': 'true',
      };

      if (customerId != null && customerId.isNotEmpty) {
        requestBody['customer'] = customerId;
      }

      requestBody['description'] = description ?? 'Ride payment - On Hold';

      final response = await http.post(
        url,
        headers: headers,
        body:  requestBody,
      );

      print('Stripe API Response Status: ${response.statusCode}');

      if (response. statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Payment intent created with HOLD');
        print('Payment Intent ID: ${responseData['id']}');
        print('Status: ${responseData['status']}'); // Should be 'requires_capture' after confirmation
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        print('Stripe API Error: ${errorData['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Exception in createPaymentIntentWithHold: $e');
      return null;
    }
  }

  /// Step 2: Capture Payment and Transfer to Driver
  /// Called when ride is complete
  static Future<Map<String, dynamic>?> captureAndTransferPayment({
    required String paymentIntentId,
    required String driverStripeAccountId, // Driver's connected account ID (acct_xxx)
    required int totalAmountCents,
    int? tipAmountCents,
  }) async {
    try {
      print('=== Starting Capture and Transfer ===');
      print('Payment Intent ID:  $paymentIntentId');
      print('Driver Stripe Account:  $driverStripeAccountId');
      print('Total Amount:  $totalAmountCents cents');
      print('Tip Amount:  ${tipAmountCents ?? 0} cents');

      // Step 2a: First capture the payment
      final captureResult = await _capturePaymentIntent(
        paymentIntentId: paymentIntentId,
        amountToCapture: totalAmountCents,
      );

      if (captureResult == null) {
        print('Failed to capture payment');
        return null;
      }

      print('Payment captured successfully');

      // Step 2b:  Calculate amounts
      int tipAmount = tipAmountCents ??  0;
      int rideAmount = totalAmountCents - tipAmount;

      // Platform fee is only on ride amount, not on tip
      int platformFee = (rideAmount * platformFeePercent).round();

      // Driver gets:  ride amount - platform fee + full tip
      int driverAmount = rideAmount - platformFee + tipAmount;

      print('=== Payment Split ===');
      print('Ride Amount: $rideAmount cents');
      print('Platform Fee (${(platformFeePercent * 100).toInt()}%): $platformFee cents');
      print('Tip (100% to driver): $tipAmount cents');
      print('Driver Total: $driverAmount cents');

      // Step 2c:  Transfer to driver
      final transferResult = await _createTransfer(
        amount: driverAmount,
        destinationAccount: driverStripeAccountId,
        sourcePaymentIntent: paymentIntentId,
        description: 'Ride payment - Driver share',
      );

      if (transferResult == null) {
        print('WARNING: Payment captured but transfer failed! ');
        // You should handle this case - maybe queue for retry
        return {
          'success': false,
          'captured':  true,
          'transferred': false,
          'error': 'Transfer to driver failed',
          'payment_intent_id':  paymentIntentId,
        };
      }

      return {
        'success': true,
        'captured': true,
        'transferred':  true,
        'payment_intent_id':  paymentIntentId,
        'transfer_id': transferResult['id'],
        'total_amount':  totalAmountCents,
        'driver_amount': driverAmount,
        'platform_fee': platformFee,
        'tip_amount':  tipAmount,
      };

    } catch (e) {
      print('Exception in captureAndTransferPayment: $e');
      return null;
    }
  }

  /// Capture a held payment intent
  static Future<Map<String, dynamic>?> _capturePaymentIntent({
    required String paymentIntentId,
    required int amountToCapture,
  }) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId/capture');

      final headers = {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version':  '2023-10-16',
      };

      final Map<String, String> requestBody = {
        'amount_to_capture': amountToCapture. toString(),
      };

      final response = await http.post(
        url,
        headers: headers,
        body:  requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Payment captured:  ${responseData['id']}');
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        print('Capture error: ${errorData['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Exception in _capturePaymentIntent:  $e');
      return null;
    }
  }

  /// Create transfer to connected account (driver)
  static Future<Map<String, dynamic>?> _createTransfer({
    required int amount,
    required String destinationAccount,
    required String sourcePaymentIntent,
    String? description,
  }) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/transfers');

      final headers = {
        'Authorization':  'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-10-16',
      };

      final Map<String, String> requestBody = {
        'amount':  amount.toString(),
        'currency': 'cad',
        'destination': destinationAccount, // Driver's connected account (acct_xxx)
        'source_transaction': sourcePaymentIntent,
      };

      if (description != null) {
        requestBody['description'] = description;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      if (response. statusCode == 200) {
        final responseData = json. decode(response.body);
        print('Transfer created: ${responseData['id']}');
        return responseData;
      } else {
        final errorData = json. decode(response.body);
        print('Transfer error: ${errorData['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Exception in _createTransfer:  $e');
      return null;
    }
  }

  /// Cancel a held payment (if ride is cancelled)
  static Future<bool> cancelHeldPayment(String paymentIntentId) async {
    try {
      final url = Uri. parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId/cancel');

      final headers = {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-10-16',
      };

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        print('Payment hold cancelled successfully');
        return true;
      } else {
        final errorData = json.decode(response.body);
        print('Cancel error: ${errorData['error']['message']}');
        return false;
      }
    } catch (e) {
      print('Exception in cancelHeldPayment:  $e');
      return false;
    }
  }

  /// Create Connected Account for Driver (Stripe Connect Onboarding)
  static Future<Map<String, dynamic>? > createDriverConnectedAccount({
    required String email,
    String? firstName,
    String?  lastName,
  }) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/accounts');

      final headers = {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-10-16',
      };

      final Map<String, String> requestBody = {
        'type': 'express', // Express accounts are easier to set up
        'country': 'CA',
        'email':  email,
        'capabilities[transfers][requested]': 'true',
        'capabilities[card_payments][requested]': 'true',
      };

      if (firstName != null) {
        requestBody['individual[first_name]'] = firstName;
      }
      if (lastName != null) {
        requestBody['individual[last_name]'] = lastName;
      }

      final response = await http.post(
        url,
        headers: headers,
        body:  requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Connected account created: ${responseData['id']}');
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        print('Error:  ${errorData['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Exception:  $e');
      return null;
    }
  }

  /// Create Account Link for Driver Onboarding
  static Future<String? > createAccountLink({
    required String accountId,
    required String refreshUrl,
    required String returnUrl,
  }) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/account_links');

      final headers = {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version':  '2023-10-16',
      };

      final Map<String, String> requestBody = {
        'account':  accountId,
        'refresh_url':  refreshUrl,
        'return_url':  returnUrl,
        'type': 'account_onboarding',
      };

      final response = await http.post(
        url,
        headers: headers,
        body:  requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['url'];
      }
      return null;
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}