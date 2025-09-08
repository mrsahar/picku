import 'package:get/get.dart';
import 'package:pick_u/core/global_variables.dart';
import 'package:pick_u/models/forgot_password_model.dart';
import 'package:pick_u/models/login_model.dart';
import 'package:pick_u/models/otp_model.dart';
import 'package:pick_u/models/reset_password_model.dart';
import 'package:pick_u/models/signup_model.dart';

class ApiProvider extends GetConnect {
  final GlobalVariables _globalVars = GlobalVariables.instance;

  @override
  void onInit() {
    super.onInit();

    // Configure base URL
    httpClient.baseUrl = _globalVars.baseUrl;

    // Add request interceptor
    httpClient.addRequestModifier<dynamic>((request) {
      print('SAHAr MRSAHAr: Request URL = ${request.url}');
      print('SAHAr MRSAHAr: Request Headers = ${request.headers}');
      print('SAHAr MRSAHAr: Request Method = ${request.method}');
      // Only add Authorization header
      if (_globalVars.userToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${_globalVars.userToken}';
      }
      return request;
    });
    // Add response interceptor
    httpClient.addResponseModifier<dynamic>((request, response) {
      print('SAHAr MRSAHAr: Response URL = ${request.url}');
      print('SAHAr MRSAHAr: Response Status = ${response.statusCode}');
      print('SAHAr MRSAHAr: Response Body = ${response.bodyString}');
      return response;
    });
  }

  // GET Request
  Future<Response> getData(String endpoint) async {
    try {
      _globalVars.setLoading(true);
      print('SAHAr MRSAHAr: GET $endpoint');
      final response = await get(endpoint);
      print('SAHAr MRSAHAr: GET Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('SAHAr MRSAHAr: Exception during GET request: $e');
      return Response(
        statusCode: 500,
        statusText: 'Network Error: $e',
      );
    }
  }
// POST Request - handles both JSON and FormData
  Future<Response> postData2(String endpoint, dynamic data) async {
    try {
      _globalVars.setLoading(true);
      print('SAHAr MRSAHAr: POST $endpoint');

      Response response;
      if (data is FormData) {
        // For FormData, don't use the interceptor - send directly
        final headers = <String, String>{};
        if (_globalVars.userToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${_globalVars.userToken}';
        }
        // Don't set Content-Type - let it be set automatically for multipart

        response = await httpClient.post(
          endpoint,
          body: data,
          headers: headers,
        );
      } else {
        // Use regular post for JSON data
        response = await post(endpoint, data);
      }

      print('SAHAr MRSAHAr: POST Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('SAHAr MRSAHAr: Exception during POST request: $e');
      return Response(
        statusCode: 500,
        statusText: 'Network Error: $e',
      );
    }
  }
  // POST Request - handles both JSON and FormData
  Future<Response> postData(String endpoint, dynamic data) async {
    try {
      _globalVars.setLoading(true);
      print('SAHAr MRSAHAr: POST $endpoint');
      print('SAHAr MRSAHAr: POST Body = $data');

      Response response;
      if (data is FormData) {
        // Use postFormData for FormData
        response = await postFormData(endpoint, data);
      } else {
        // Use regular post for JSON data
        response = await post(endpoint, data);
      }

      print('SAHAr MRSAHAr: POST Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('SAHAr MRSAHAr: Exception during POST request: $e');
      return Response(
        statusCode: 500,
        statusText: 'Network Error: $e',
      );
    }
  }

  // Specific method for FormData POST requests
  Future<Response> postFormData(String endpoint, FormData formData) async {
    try {
      _globalVars.setLoading(true);
      print('SAHAr MRSAHAr: POST FormData $endpoint');

      // Debug FormData contents
      print('SAHAr FormData Fields:');
      formData.fields.forEach((field) {
        print('SAHAr ${field.key} = ${field.value}');
      });

      print('SAHAr FormData Files:');
      formData.files.forEach((file) {
        print('SAHAr ${file.key} = ${file.value.filename}');
      });

      // Create custom headers for FormData
      final headers = <String, String>{};
      if (_globalVars.userToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_globalVars.userToken}';
      }
      // Don't set Content-Type - let dio handle it automatically for FormData

      final response = await httpClient.post(
        endpoint,
        body: formData,
        headers: headers,
      );

      print('SAHAr MRSAHAr: FormData Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('SAHAr MRSAHAr: Exception during FormData POST request: $e');
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
      print('SAHAr MRSAHAr: PUT $endpoint');
      print('SAHAr MRSAHAr: PUT Body = $data');
      final response = await put(endpoint, data);
      print('SAHAr MRSAHAr: PUT Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print('SAHAr MRSAHAr: Exception during PUT request: $e');
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
      print('SAHAr 🚀MRSAHAr ApiProvider: Starting signUp request');
      print('SAHAr 📦MRSAHAr ApiProvider: Request data: ${request.toJson()}');

      final response = await postData('/api/User/register', request.toJson());

      print('SAHAr 📨MRSAHAr ApiProvider: Response received');
      print('SAHAr 📊MRSAHAr ApiProvider: Status Code: ${response.statusCode}');
      print('SAHAr 📄MRSAHAr ApiProvider: Response Body: ${response.body}');
      print('SAHAr 📝MRSAHAr ApiProvider: Response Type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SAHAr ✅MRSAHAr ApiProvider: Success status code');

        String message = 'Registration successful';
        dynamic data = response.body;

        // Handle different response body types
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message']?.toString() ?? message;
            print('SAHAr 📝MRSAHAr ApiProvider: Extracted message from Map: $message');
          } else if (response.body is String) {
            // String response
            message = response.body;
            print('SAHAr 📝MRSAHAr ApiProvider: Using String response: $message');
          } else if (response.body is List) {
            // Array response
            message = 'Registration successful';
            print('SAHAr 📝MRSAHAr ApiProvider: Array response received');
          } else {
            // Other types
            message = 'Registration successful';
            print('SAHAr 📝MRSAHAr ApiProvider: Unknown response type: ${response.body.runtimeType}');
          }
        }

        return SignUpResponse(
          success: true,
          message: message,
          data: data,
        );

      } else {
        print('SAHAr ❌MRSAHAr ApiProvider: Error status code: ${response.statusCode}');

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

        print('SAHAr 📝MRSAHAr ApiProvider: Error message: $errorMessage');

        return SignUpResponse(
          success: false,
          message: errorMessage,
        );
      }

    } catch (e, stackTrace) {
      print('SAHAr 💥MRSAHAr ApiProvider: Exception in signUp: $e');
      print('SAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

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
      print('SAHAr 🚀MRSAHAr ApiProvider: Starting OTP verification for: ${_globalVars.baseUrl}/api/User/verify');
      print('SAHAr 📦MRSAHAr ApiProvider: OTP Request data: ${request.toJson()}');

      final response = await postData('/api/User/verify', request.toJson());

      print('SAHAr 📋MRSAHAr ApiProvider: OTP response received');
      print('SAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print('SAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SAHAr ✅MRSAHAr ApiProvider: OTP verification successful');

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
        print('SAHAr ❌MRSAHAr ApiProvider: OTP verification failed with status: ${response.statusCode}');

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
      print('SAHAr 💥MRSAHAr ApiProvider: OTP verification exception: $e');
      print('SAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return OTPResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('SAHAr 🚀MRSAHAr ApiProvider: Starting login for: ${_globalVars.baseUrl}/api/User/login');
      print('SAHAr 📦MRSAHAr ApiProvider: Login Request data: ${request.toJson()}');

      final response = await postData('/api/User/login', request.toJson());

      print('SAHAr 📋MRSAHAr ApiProvider: Login response received');
      print('SAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print('SAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SAHAr ✅MRSAHAr ApiProvider: Login successful');

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
        print('SAHAr ❌MRSAHAr ApiProvider: Login failed with status: ${response.statusCode}');

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
      print('SAHAr 💥MRSAHAr ApiProvider: Login exception: $e');
      print('SAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return LoginResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      print('SAHAr 🚀MRSAHAr ApiProvider: Starting forgot password for: ${_globalVars.baseUrl}/api/User/forgot-password');
      print('SAHAr 📦MRSAHAr ApiProvider: ForgotPassword Request data: ${request.toJson()}');

      final response = await postData('/api/User/forgot-password', request.toJson());

      print('SAHAr 📋MRSAHAr ApiProvider: ForgotPassword response received');
      print('SAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print('SAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');
      print('SAHAr 📝MRSAHAr ApiProvider: Response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SAHAr ✅MRSAHAr ApiProvider: ForgotPassword successful');

        String message = 'Reset email sent successfully';
        dynamic data = response.body;

        // Handle different response formats
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message'] ?? message;
            data = bodyMap;
            print('SAHAr 📝MRSAHAr ApiProvider: JSON response received');
          } else if (response.body is String && response.body.isNotEmpty) {
            // String response
            message = response.body;
            print('SAHAr 📝MRSAHAr ApiProvider: String response received');
          } else {
            message = 'Reset email sent successfully';
            print('SAHAr 📝MRSAHAr ApiProvider: Default message used');
          }
        }

        return ForgotPasswordResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print('SAHAr ❌MRSAHAr ApiProvider: ForgotPassword failed with status: ${response.statusCode}');

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
      print('SAHAr 💥MRSAHAr ApiProvider: ForgotPassword exception: $e');
      print('SAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return ForgotPasswordResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      print('SAHAr 🚀 ApiProvider: Starting reset password for: ${_globalVars.baseUrl}/api/User/reset-password');
      print('SAHAr 📦 ApiProvider: ResetPassword Request data: ${request.toJson()}');

      final response = await postData('/api/User/reset-password', request.toJson());

      print('SAHAr 📋 ApiProvider: ResetPassword response received');
      print('SAHAr 📊 ApiProvider: Response status code: ${response.statusCode}');
      print('SAHAr 📄 ApiProvider: Response body: ${response.body}');
      print('SAHAr 📝 ApiProvider: Response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SAHAr ✅ ApiProvider: ResetPassword successful');

        String message = 'Password reset successfully';
        dynamic data = response.body;

        // Handle different response formats
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message'] ?? message;
            data = bodyMap;
            print('SAHAr 📝 ApiProvider: JSON response received');
          } else if (response.body is String && response.body.isNotEmpty) {
            // String response
            message = response.body;
            print('SAHAr 📝 ApiProvider: String response received');
          } else {
            message = 'Password reset successfully';
            print('SAHAr 📝 ApiProvider: Default message used');
          }
        }

        return ResetPasswordResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print('SAHAr ❌ ApiProvider: ResetPassword failed with status: ${response.statusCode}');

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
      print('SAHAr 💥 ApiProvider: ResetPassword exception: $e');
      print('SAHAr 📍 ApiProvider: Stack trace: $stackTrace');

      return ResetPasswordResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

}