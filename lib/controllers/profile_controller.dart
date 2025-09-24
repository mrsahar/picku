import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/core/sharePref.dart';
import 'package:pick_u/providers/api_provider.dart';

import '../models/user_profile_model.dart';

class ProfileController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Observable variables
  var isLoading = true.obs;
  var userProfile = Rxn<UserProfileModel>();
  var profileImage = Rxn<Uint8List>();
  var isImageLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;

      // Get user ID from SharedPreferences
      String? userId = await SharedPrefsService.getUserId();

      if (userId == null) {
        Get.snackbar('Error', 'User ID not found');
        return;
      }

      // API call to get user profile using ApiProvider
      final response = await _apiProvider.postData('/api/User/single-users/$userId', {});

      print(' SAHArSAHAr Response Status Code: ${response.statusCode}');
      print(' SAHArSAHAr Response Body: ${response.body}');

      if (response.statusCode == 200 && response.body != null) {
        userProfile.value = UserProfileModel.fromJson(response.body);

        // Extract and set profile image if available
        if (userProfile.value != null && userProfile.value!.hasProfilePicture) {
          profileImage.value = userProfile.value!.getImageBytes();
          print(' SAHArSAHAr Profile image loaded successfully');
        } else {
          profileImage.value = null;
          print(' SAHArSAHAr No profile image available');
        }
      } else {
        Get.snackbar('Error', 'Failed to load profile: ${response.statusText ?? 'Unknown error'}');
      }
    } catch (e) {
      print(' SAHArSAHAr Exception in fetchUserProfile: ${e.toString()}');
      Get.snackbar('Error', 'Failed to load profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to update profile image separately if needed
  void updateProfileImage() {
    if (userProfile.value != null && userProfile.value!.hasProfilePicture) {
      profileImage.value = userProfile.value!.getImageBytes();
    } else {
      profileImage.value = null;
    }
  }

  // Method to check if profile image is available
  bool get hasProfileImage => profileImage.value != null;

  Future<void> logout() async {
    try {
      bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Clear user data from SharedPreferences
        await SharedPrefsService.clearUserData();

        // Navigate to login screen and remove all previous routes
        Get.offAllNamed('/login');

        Get.snackbar('Success', 'Logged out successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }

  void refreshProfile() {
    fetchUserProfile();
  }
}