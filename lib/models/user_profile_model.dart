import 'dart:convert';
import 'dart:typed_data';

class UserProfileModel {
  final String userId;
  final String name;
  final String phoneNumber;
  final bool hasImage;
  final String? profilePicture; // Base64 string

  UserProfileModel({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.hasImage,
    this.profilePicture,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      hasImage: json['hasImage'] ?? false,
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'hasImage': hasImage,
      'profilePicture': profilePicture,
    };
  }

  // Helper method to get image bytes from base64 string
  Uint8List? getImageBytes() {
    if (profilePicture == null || profilePicture!.isEmpty) {
      return null;
    }

    try {
      // Remove the data URL prefix if it exists (data:image/jpeg;base64,)
      String base64String = profilePicture!;
      if (base64String.contains(',')) {
        base64String = base64String.split(',')[1];
      }

      return base64Decode(base64String);
    } catch (e) {
      print(' SAHArSAHAr Error decoding base64 image: $e');
      return null;
    }
  }

  // Helper method to check if profile picture is available
  bool get hasProfilePicture => profilePicture != null && profilePicture!.isNotEmpty;

  // Helper method to get the image format from base64 string
  String? get imageFormat {
    if (profilePicture == null || !profilePicture!.contains('data:image/')) {
      return null;
    }

    try {
      final prefix = profilePicture!.split(';')[0];
      return prefix.split('/')[1]; // Returns 'jpeg', 'png', etc.
    } catch (e) {
      return null;
    }
  }
}