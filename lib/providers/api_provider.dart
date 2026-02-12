import 'package:get/get.dart';
import 'package:pick_u/services/global_variables.dart';
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
    httpClient.timeout = const Duration(seconds: 50);
    // Configure base URL
    httpClient.baseUrl = _globalVars.baseUrl;

    // Add request interceptor
    httpClient.addRequestModifier<dynamic>((request) {
      print(' SAHArSAHAr MRSAHAr: Request URL = ${request.url}');
      print(' SAHArSAHAr MRSAHAr: Request Headers = ${request.headers}');
      print(' SAHArSAHAr MRSAHAr: Request Method = ${request.method}');
      // Only add Authorization header
      if (_globalVars.userToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${_globalVars.userToken}';
      }
      return request;
    });
    // Add response interceptor
    httpClient.addResponseModifier<dynamic>((request, response) {
      print(' SAHArSAHAr MRSAHAr: Response URL = ${request.url}');
      print(' SAHArSAHAr MRSAHAr: Response Status = ${response.statusCode}');
      print(' SAHArSAHAr MRSAHAr: Response Body = ${response.bodyString}');
      return response;
    });
  }

  // GET Request
  Future<Response> getData(String endpoint) async {
    try {
      _globalVars.setLoading(true);
      print(' SAHArSAHAr MRSAHAr: GET $endpoint');
      final response = await get(endpoint);
      print(' SAHArSAHAr MRSAHAr: GET Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print(' SAHArSAHAr MRSAHAr: Exception during GET request: $e');
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
      print(' SAHArSAHAr MRSAHAr: POST $endpoint');

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

      print(' SAHArSAHAr MRSAHAr: POST Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print(' SAHArSAHAr MRSAHAr: Exception during POST request: $e');
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
      print(' SAHArSAHAr MRSAHAr: POST $endpoint');
      print(' SAHArSAHAr MRSAHAr: POST Body = $data');

      Response response;
      if (data is FormData) {
        // Use postFormData for FormData
        response = await postFormData(endpoint, data);
      } else {
        // Use regular post for JSON data
        response = await post(endpoint, data);
      }

      print(' SAHArSAHAr MRSAHAr: POST Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print(' SAHArSAHAr MRSAHAr: Exception during POST request: $e');
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
      print(' SAHArSAHAr MRSAHAr: POST FormData $endpoint');

      // Debug FormData contents
      print(' SAHArSAHAr FormData Fields:');
      formData.fields.forEach((field) {
        print(' SAHArSAHAr ${field.key} = ${field.value}');
      });

      print(' SAHArSAHAr FormData Files:');
      formData.files.forEach((file) {
        print(' SAHArSAHAr ${file.key} = ${file.value.filename}');
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

      print(' SAHArSAHAr MRSAHAr: FormData Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print(' SAHArSAHAr MRSAHAr: Exception during FormData POST request: $e');
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
      print(' SAHArSAHAr MRSAHAr: PUT $endpoint');
      print(' SAHArSAHAr MRSAHAr: PUT Body = $data');
      final response = await put(endpoint, data);
      print(' SAHArSAHAr MRSAHAr: PUT Response = ${response.bodyString}');
      _globalVars.setLoading(false);
      return response;
    } catch (e) {
      _globalVars.setLoading(false);
      print(' SAHArSAHAr MRSAHAr: Exception during PUT request: $e');
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
      print(' SAHArSAHAr 🚀MRSAHAr ApiProvider: Starting signUp request');
      print(' SAHArSAHAr 📦MRSAHAr ApiProvider: Request data: ${request.toJson()}');

      final response = await postData('/api/User/register', request.toJson());

      print(' SAHArSAHAr 📨MRSAHAr ApiProvider: Response received');
      print(' SAHArSAHAr 📊MRSAHAr ApiProvider: Status Code: ${response.statusCode}');
      print(' SAHArSAHAr 📄MRSAHAr ApiProvider: Response Body: ${response.body}');
      print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Response Type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(' SAHArSAHAr ✅MRSAHAr ApiProvider: Success status code');

        String message = 'Registration successful';
        dynamic data = response.body;

        // Handle different response body types
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message']?.toString() ?? message;
            print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Extracted message from Map: $message');
          } else if (response.body is String) {
            // String response
            message = response.body;
            print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Using String response: $message');
          } else if (response.body is List) {
            // Array response
            message = 'Registration successful';
            print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Array response received');
          } else {
            // Other types
            message = 'Registration successful';
            print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Unknown response type: ${response.body.runtimeType}');
          }
        }

        return SignUpResponse(
          success: true,
          message: message,
          data: data,
        );

      } else {
        print(' SAHArSAHAr ❌MRSAHAr ApiProvider: Error status code: ${response.statusCode}');

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

        print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Error message: $errorMessage');

        return SignUpResponse(
          success: false,
          message: errorMessage,
        );
      }

    } catch (e, stackTrace) {
      print(' SAHArSAHAr 💥MRSAHAr ApiProvider: Exception in signUp: $e');
      print(' SAHArSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

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
      print(' SAHArSAHAr 🚀MRSAHAr ApiProvider: Starting OTP verification for: ${_globalVars.baseUrl}/api/User/verify');
      print(' SAHArSAHAr 📦MRSAHAr ApiProvider: OTP Request data: ${request.toJson()}');

      final response = await postData('/api/User/verify', request.toJson());

      print(' SAHArSAHAr 📋MRSAHAr ApiProvider: OTP response received');
      print(' SAHArSAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print(' SAHArSAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(' SAHArSAHAr ✅MRSAHAr ApiProvider: OTP verification successful');

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
        print(' SAHArSAHAr ❌MRSAHAr ApiProvider: OTP verification failed with status: ${response.statusCode}');

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
      print(' SAHArSAHAr 💥MRSAHAr ApiProvider: OTP verification exception: $e');
      print(' SAHArSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return OTPResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print(' SAHArSAHAr 🚀MRSAHAr ApiProvider: Starting login for: ${_globalVars.baseUrl}/api/User/login');
      print(' SAHArSAHAr 📦MRSAHAr ApiProvider: Login Request data: ${request.toJson()}');

      final response = await postData('/api/User/login', request.toJson());

      print(' SAHArSAHAr 📋MRSAHAr ApiProvider: Login response received');
      print(' SAHArSAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print(' SAHArSAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(' SAHArSAHAr ✅MRSAHAr ApiProvider: Login successful');

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
        print(' SAHArSAHAr ❌MRSAHAr ApiProvider: Login failed with status: ${response.statusCode}');

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
      print(' SAHArSAHAr 💥MRSAHAr ApiProvider: Login exception: $e');
      print(' SAHArSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return LoginResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      print(' SAHArSAHAr 🚀MRSAHAr ApiProvider: Starting forgot password for: ${_globalVars.baseUrl}/api/User/forgot-password');
      print(' SAHArSAHAr 📦MRSAHAr ApiProvider: ForgotPassword Request data: ${request.toJson()}');

      final response = await postData('/api/User/forgot-password', request.toJson());

      print(' SAHArSAHAr 📋MRSAHAr ApiProvider: ForgotPassword response received');
      print(' SAHArSAHAr 📊MRSAHAr ApiProvider: Response status code: ${response.statusCode}');
      print(' SAHArSAHAr 📄MRSAHAr ApiProvider: Response body: ${response.body}');
      print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(' SAHArSAHAr ✅MRSAHAr ApiProvider: ForgotPassword successful');

        String message = 'Reset email sent successfully';
        dynamic data = response.body;

        // Handle different response formats
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message'] ?? message;
            data = bodyMap;
            print(' SAHArSAHAr 📝MRSAHAr ApiProvider: JSON response received');
          } else if (response.body is String && response.body.isNotEmpty) {
            // String response
            message = response.body;
            print(' SAHArSAHAr 📝MRSAHAr ApiProvider: String response received');
          } else {
            message = 'Reset email sent successfully';
            print(' SAHArSAHAr 📝MRSAHAr ApiProvider: Default message used');
          }
        }

        return ForgotPasswordResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print(' SAHArSAHAr ❌MRSAHAr ApiProvider: ForgotPassword failed with status: ${response.statusCode}');

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
      print(' SAHArSAHAr 💥MRSAHAr ApiProvider: ForgotPassword exception: $e');
      print(' SAHArSAHAr 📍MRSAHAr ApiProvider: Stack trace: $stackTrace');

      return ForgotPasswordResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      print(' SAHArSAHAr 🚀 ApiProvider: Starting reset password for: ${_globalVars.baseUrl}/api/User/reset-password');
      print(' SAHArSAHAr 📦 ApiProvider: ResetPassword Request data: ${request.toJson()}');

      final response = await postData('/api/User/reset-password', request.toJson());

      print(' SAHArSAHAr 📋 ApiProvider: ResetPassword response received');
      print(' SAHArSAHAr 📊 ApiProvider: Response status code: ${response.statusCode}');
      print(' SAHArSAHAr 📄 ApiProvider: Response body: ${response.body}');
      print(' SAHArSAHAr 📝 ApiProvider: Response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(' SAHArSAHAr ✅ ApiProvider: ResetPassword successful');

        String message = 'Password reset successfully';
        dynamic data = response.body;

        // Handle different response formats
        if (response.body != null) {
          if (response.body is Map<String, dynamic>) {
            // JSON response
            final Map<String, dynamic> bodyMap = response.body;
            message = bodyMap['message'] ?? message;
            data = bodyMap;
            print(' SAHArSAHAr 📝 ApiProvider: JSON response received');
          } else if (response.body is String && response.body.isNotEmpty) {
            // String response
            message = response.body;
            print(' SAHArSAHAr 📝 ApiProvider: String response received');
          } else {
            message = 'Password reset successfully';
            print(' SAHArSAHAr 📝 ApiProvider: Default message used');
          }
        }

        return ResetPasswordResponse(
          success: true,
          message: message,
          data: data,
        );
      } else {
        print(' SAHArSAHAr ❌ ApiProvider: ResetPassword failed with status: ${response.statusCode}');

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
      print(' SAHArSAHAr 💥 ApiProvider: ResetPassword exception: $e');
      print(' SAHArSAHAr 📍 ApiProvider: Stack trace: $stackTrace');

      return ResetPasswordResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

}