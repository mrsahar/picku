// models/otp_model.dart
class OTPRequest {
  final String email;
  final String otp;

  OTPRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

class OTPResponse {
  final bool success;
  final String message;
  final dynamic data;

  OTPResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OTPResponse.fromJson(Map<String, dynamic> json) {
    return OTPResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}