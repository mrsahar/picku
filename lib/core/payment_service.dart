import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  // Get keys from .env file
  static String get secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';
  static String get publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  // Stripe API - Create Payment Intent (Fixed)
  static Future<Map<String, dynamic>?> createPaymentIntent({
    required String amount, // amount in cents
    required String currency, // 'cad' for Canadian dollars
    String? customerId,
    String? description,
  }) async {
    try {
      print('Creating payment intent with Stripe API');
      print('Amount: $amount cents, Currency: $currency');

      // Correct Stripe API endpoint
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

      // Request headers
      final headers = {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2020-08-27',
      };

      // Request body as form data
      final Map<String, String> requestBody = {
        'amount': amount,
        'currency': currency.toLowerCase(),
        'automatic_payment_methods[enabled]': 'true',
      };

      // Optional parameters
      if (customerId != null && customerId.isNotEmpty) {
        requestBody['customer'] = customerId;
      }

      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      } else {
        requestBody['description'] = 'Ride payment';
      }

      print('Making HTTP request to Stripe API...');
      print('Request body: $requestBody');

      // Make HTTP POST request to Stripe
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      print('Stripe API Response Status: ${response.statusCode}');
      print('Stripe API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Payment intent created successfully');
        print('Payment Intent ID: ${responseData['id']}');
        print('Client Secret: ${responseData['client_secret']}');

        return responseData;
      } else {
        final errorData = json.decode(response.body);
        print('Stripe API Error: ${response.statusCode}');
        print('Error details: ${errorData['error']['message']}');
        print('Error type: ${errorData['error']['type']}');
        return null;
      }

    } catch (e) {
      print('Exception in createPaymentIntent: $e');
      return null;
    }
  }

  // Create Customer (Fixed)
  static Future<Map<String, dynamic>?> createCustomer({
    required String email,
    String? name,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('Creating customer with Stripe API');

      final url = Uri.parse('https://api.stripe.com/v1/customers');

      final headers = {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2020-08-27',
      };

      final Map<String, String> requestBody = {
        'email': email,
      };

      if (name != null && name.isNotEmpty) {
        requestBody['name'] = name;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Customer created successfully: ${responseData['id']}');
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        print('Customer creation error: ${errorData['error']['message']}');
        return null;
      }

    } catch (e) {
      print('Exception in createCustomer: $e');
      return null;
    }
  }

  // Helper method to validate amount
  static String validateAndFormatAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }

    // Convert to cents and ensure it's an integer
    int amountInCents = (amount * 100).round();

    // Minimum charge amount for most currencies is 50 cents
    if (amountInCents < 50) {
      throw ArgumentError('Amount must be at least 0.50');
    }

    return amountInCents.toString();
  }

  // Check if keys are properly loaded
  static bool areKeysValid() {
    return secretKey.isNotEmpty &&
        publishableKey.isNotEmpty &&
        secretKey.startsWith('sk_') &&
        publishableKey.startsWith('pk_');
  }
}