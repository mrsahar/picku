import 'dart:io';

import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/models/forgot_password_model.dart';
import 'package:pick_u/models/login_model.dart';
import 'package:pick_u/models/otp_model.dart';
import 'package:pick_u/models/reset_password_model.dart';
import 'package:pick_u/models/signup_model.dart';
import 'package:image/image.dart' as img;

class ApiProvider extends GetConnect {
  final GlobalVariables _globalVars = GlobalVariables.instance;

  @override
  void onInit() {
    super.onInit();

    // Configure base URL
    httpClient.baseUrl = _globalVars.baseUrl;

    // Add request interceptor
    httpClient.addRequestModifier<dynamic>((request) {
      print('MRSAHAr MRSAHAr: Request URL = ${request.url}');
      print('MRSAHAr MRSAHAr: Request Headers = ${request.headers}');
      print('MRSAHAr MRSAHAr: Request Method = ${request.method}');

      request.headers['Content-Type'] = 'application/json';
      if (_globalVars.userToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${_globalVars.userToken}';
      }
      return request;
    });

    // Add response interceptor
    httpClient.addResponseModifier<dynamic>((request, response) {
      print('MRSAHAr MRSAHAr: Response URL = ${request.url}');
      print('MRSAHAr MRSAHAr: Response Status = ${response.statusCode}');
      print('MRSAHAr MRSAHAr: Response Body = ${response.bodyString}');
      return response;
    });
  }

  // GET Request
  Future<Response> getData(String endpoint) async {
    try {
      _globalVars.setLoading(true);
      print('MRSAHAr MRSAHAr: GET $endpoint');
      final response = await get(endpoint);
      print('MRSAHAr MRSAHAr: GET Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('MRSAHAr MRSAHAr: Exception during GET request: $e');
      return Response(
        statusCode: 500,
        statusText: 'Network Error: $e',
      );
    }
  }

  // POST Request
  Future<Response> postData(String endpoint, Map<String, dynamic> data) async {
    try {
      _globalVars.setLoading(true);
      print('MRSAHAr MRSAHAr: POST $endpoint');
      print('MRSAHAr MRSAHAr: POST Body = $data');
      final response = await post(endpoint, data);
      print('MRSAHAr MRSAHAr: POST Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('MRSAHAr MRSAHAr: Exception during POST request: $e');
      return Response(
        statusCode: 500,
        statusText: 'Network Error: $e',
      );
    }
  }

  // PUT Request
  Future<Response> putData(String endpoint, Map<String, dynamic> data) async {
    try {
      _globalVars.setLoading(true);
      print('MRSAHAr MRSAHAr: PUT $endpoint');
      print('MRSAHAr MRSAHAr: PUT Body = $data');
      final response = await put(endpoint, data);
      print('MRSAHAr MRSAHAr: PUT Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('MRSAHAr MRSAHAr: Exception during PUT request: $e');
      return Response(
        statusCode: 500,
        statusText: 'Network Error: $e',
      );
    }
  }


  // DELETE Request
  Future<Response> deleteData(String endpoint) async {
    try {
      _globalVars.setLoading(true);
      final response = await delete(endpoint);
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      return Response(
        statusCode: 500,
        statusText: 'Network Error: $e',
      );
    }
  }

  // Replace your signUp method with this robust version
  Future<SignUpResponse> signUp(SignUpRequest request) async {
    try {
      print('MRSAHAr 🚀MRSAHAr ApiProvider: Starting signUp request');
      print('MRSAHAr 📦MRSAHAr ApiProvider: Request data: ${request.toJson()}');

      final response = await postData('/api/User/register', request.toJson());

      print('MRSAHAr 📨MRSAHAr ApiProvider: Response received');
      print('MRSAHAr 📊MRSAHAr ApiProvider: Status Code: ${response.statusCode}');
      print('MRSAHAr 📄MRSAHAr ApiProvider: Response Body: ${response.body}');
      print('MRSAHAr 📝MRSAHAr ApiProvider: Response Type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MRSAHAr ✅MRSAHAr ApiProvider: Success status code');

        String message = 'Registration successful';
        dynamic data = response.body;

        // Handle different response body types
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message']?.toString() ?? message;
            print('MRSAHAr 📝MRSAHAr ApiProvider: Extracted message from Map: $message');
          } else if (response.body is String) {
            // String response
            message = response.body;
            print('MRSAHAr 📝MRSAHAr ApiProvider: Using String response: $message');
          } else if (response.body is List) {
            // Array response
            message = 'Registration successful';
            print('MRSAHAr 📝MRSAHAr ApiProvider: Array response received');
          } else {
            // Other types
            message = 'Registration successful';
            print('MRSAHAr 📝MRSAHAr ApiProvider: Unknown response type: ${response.body.runtimeType}');
          }
        }

        return SignUpResponse(
          success: true,
          message: message,
          data: data,
        );

      } else {
        print('MRSAHAr ❌MRSAHAr ApiProvider: Error status code: ${response.statusCode}');

        String errorMessage = 'Registration failed';

        // Handle error response body
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            final Map<String, dynamic> bodyMap = response.body;
            errorMessage = bodyMap['message']?.toString() ??
                bodyMap['error']?.toString() ??
                errorMessage;
          } else if (response.body is String) {
            errorMessage = response.body;
          } else {
            errorMessage = 'Registration failed with status: ${response.statusCode}';
          }
        }

        print('MRSAHAr 📝MRSAHAr ApiProvider: Error message: $errorMessage');

        return SignUpResponse(
          success: false,
          message: errorMessage,
        );
      }

    } catch (e, stackTrace) {
      print('MRSAHAr 💥MRSAHAr ApiProvider: Exception in signUp: $e');
      print('MRSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      String errorMessage = 'Network error. Please check your connection.';

      // Handle specific error types
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Connection failed. Please check your internet.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server.';
      } else if (e.toString().contains('type \'Null\'')) {
        errorMessage = 'Invalid response format from server.';
      }

      return SignUpResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  Future<OTPResponse> verifyOTP(OTPRequest request) async {
    try {
      print('MRSAHAr 🚀MRSAHAr ApiProvider: Starting OTP verification for: ${_globalVars.baseUrl}/api/User/verify');
      print('MRSAHAr 📦MRSAHAr ApiProvider: OTP Request data: ${request.toJson()}');

      final response = await postData('/api/User/verify', request.toJson());

      print('MRSAHAr 📋MRSAHAr ApiProvider: OTP response received');
      print('MRSAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print('MRSAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MRSAHAr ✅MRSAHAr ApiProvider: OTP verification successful');

        String message = 'OTP verified successfully';
        dynamic data = response.body;

        if (response.body != null && response.body is Map<String, dynamic>) {
          message = response.body['message'] ?? message;
        }

        return OTPResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print('MRSAHAr ❌MRSAHAr ApiProvider: OTP verification failed with status: ${response.statusCode}');

        String errorMessage = 'OTP verification failed';
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            errorMessage = response.body['message'] ?? errorMessage;
          } else if (response.body is String) {
            errorMessage = response.body;
          }
        }

        return OTPResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      print('MRSAHAr 💥MRSAHAr ApiProvider: OTP verification exception: $e');
      print('MRSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return OTPResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('MRSAHAr 🚀MRSAHAr ApiProvider: Starting login for: ${_globalVars.baseUrl}/api/User/login');
      print('MRSAHAr 📦MRSAHAr ApiProvider: Login Request data: ${request.toJson()}');

      final response = await postData('/api/User/login', request.toJson());

      print('MRSAHAr 📋MRSAHAr ApiProvider: Login response received');
      print('MRSAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print('MRSAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MRSAHAr ✅MRSAHAr ApiProvider: Login successful');

        String message = 'Login successful';
        dynamic data = response.body;

        if (response.body != null && response.body is Map<String, dynamic>) {
          message = response.body['message'] ?? message;
        }

        return LoginResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print('MRSAHAr ❌MRSAHAr ApiProvider: Login failed with status: ${response.statusCode}');

        String errorMessage = 'Login failed';
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            errorMessage = response.body['message'] ?? errorMessage;
          } else if (response.body is String) {
            errorMessage = response.body;
          }
        }

        return LoginResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      print('MRSAHAr 💥MRSAHAr ApiProvider: Login exception: $e');
      print('MRSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return LoginResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      print('MRSAHAr 🚀MRSAHAr ApiProvider: Starting forgot password for: ${_globalVars.baseUrl}/api/User/forgot-password');
      print('MRSAHAr 📦MRSAHAr ApiProvider: ForgotPassword Request data: ${request.toJson()}');

      final response = await postData('/api/User/forgot-password', request.toJson());

      print('MRSAHAr 📋MRSAHAr ApiProvider: ForgotPassword response received');
      print('MRSAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print('MRSAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');
      print('MRSAHAr 📝MRSAHAr ApiProvider: Response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MRSAHAr ✅MRSAHAr ApiProvider: ForgotPassword successful');

        String message = 'Reset email sent successfully';
        dynamic data = response.body;

        // Handle different response formats
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message'] ?? message;
            data = bodyMap;
            print('MRSAHAr 📝MRSAHAr ApiProvider: JSON response received');
          } else if (response.body is String && response.body.isNotEmpty) {
            // String response
            message = response.body;
            print('MRSAHAr 📝MRSAHAr ApiProvider: String response received');
          } else {
            message = 'Reset email sent successfully';
            print('MRSAHAr 📝MRSAHAr ApiProvider: Default message used');
          }
        }

        return ForgotPasswordResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print('MRSAHAr ❌MRSAHAr ApiProvider: ForgotPassword failed with status: ${response.statusCode}');

        String errorMessage = 'Failed to send reset email';
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            errorMessage = response.body['message'] ?? errorMessage;
          } else if (response.body is String && response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }

        return ForgotPasswordResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      print('MRSAHAr 💥MRSAHAr ApiProvider: ForgotPassword exception: $e');
      print('MRSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return ForgotPasswordResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      print('MRSAHAr 🚀 ApiProvider: Starting reset password for: ${_globalVars.baseUrl}/api/User/reset-password');
      print('MRSAHAr 📦 ApiProvider: ResetPassword Request data: ${request.toJson()}');

      final response = await postData('/api/User/reset-password', request.toJson());

      print('MRSAHAr 📋 ApiProvider: ResetPassword response received');
      print('MRSAHAr 📊 ApiProvider: Response status code: ${response.statusCode}');
      print('MRSAHAr 📄 ApiProvider: Response body: ${response.body}');
      print('MRSAHAr 📝 ApiProvider: Response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MRSAHAr ✅ ApiProvider: ResetPassword successful');

        String message = 'Password reset successfully';
        dynamic data = response.body;

        // Handle different response formats
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message'] ?? message;
            data = bodyMap;
            print('MRSAHAr 📝 ApiProvider: JSON response received');
          } else if (response.body is String && response.body.isNotEmpty) {
            // String response
            message = response.body;
            print('MRSAHAr 📝 ApiProvider: String response received');
          } else {
            message = 'Password reset successfully';
            print('MRSAHAr 📝 ApiProvider: Default message used');
          }
        }

        return ResetPasswordResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print('MRSAHAr ❌ ApiProvider: ResetPassword failed with status: ${response.statusCode}');

        String errorMessage = 'Failed to reset password';
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            errorMessage = response.body['message'] ?? errorMessage;
          } else if (response.body is String && response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }

        return ResetPasswordResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      print('MRSAHAr 💥 ApiProvider: ResetPassword exception: $e');
      print('MRSAHAr 📍 ApiProvider: Stack trace: $stackTrace');

      return ResetPasswordResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

}