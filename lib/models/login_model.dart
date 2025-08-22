// models/login_model.dart
class LoginRequest {
  final String email;
  final String password;
  final String deviceToken;

  LoginRequest({
    required this.email,
    required this.password,
    required this.deviceToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'deviceToken': deviceToken,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final dynamic data;

  LoginResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}