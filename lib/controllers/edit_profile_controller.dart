import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_u/services/sharePref.dart';
import 'package:pick_u/models/user_profile_model.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class EditProfileController extends GetxController {

  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  // Form controllers
  final TextEditingController txtUserName = TextEditingController();
  final TextEditingController txtMobile = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Observable variables
  var selectedImagePath = ''.obs;
  var isLoading = false.obs;
  var user = Rxn<UserProfileModel>();
  var currentProfileImage = Rxn<Uint8List>(); // For displaying current profile image

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    // Load user data passed as argument
    loadUserData();
  }

  @override
  void onClose() {
    txtUserName.dispose();
    txtMobile.dispose();
    super.onClose();
  }

  // Load current user data from arguments
  void loadUserData() {
    try {
      var userData = Get.arguments as UserProfileModel?;
      if (userData != null) {
        user.value = userData;

        // Set form field values
        txtUserName.text = userData.name;
        txtMobile.text = userData.phoneNumber;

        // Set current profile image if available
        if (userData.hasProfilePicture) {
          currentProfileImage.value = userData.getImageBytes();
        }
        print(' SAHArSAHAr User data loaded: ${userData.name}');
      }
    } catch (e) {
      print(' SAHArSAHAr Error loading user data: $e');
      Get.snackbar(
        'Error',
        'Failed to load user data',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Check if we have a profile image to display
  bool get hasDisplayImage => selectedImagePath.value.isNotEmpty || currentProfileImage.value != null;

  // Get the image to display (newly selected or current profile image)
  Widget getProfileImageWidget() {
    if (selectedImagePath.value.isNotEmpty) {
      // Show newly selected image
      return Image.file(
        File(selectedImagePath.value),
        fit: BoxFit.cover,
      );
    } else if (currentProfileImage.value != null) {
      // Show current profile image from server
      return Image.memory(
        currentProfileImage.value!,
        fit: BoxFit.cover,
      );
    } else {
      // Show placeholder
      return const Image(
        image: AssetImage("assets/img/user_placeholder.png"),
        fit: BoxFit.cover,
      );
    }
  }

  // Pick image from gallery or camera
  void pickImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImagePath.value = pickedFile.path;
        print(' SAHArSAHAr Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Show image picker options
  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Profile Picture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.back();
                    pickImage(fromCamera: true);
                  },
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt, size: 25, color: MColor.primaryNavy),
                      Text('Camera'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.back();
                    pickImage(fromCamera: false);
                  },
                  child: Column(
                    children: [
                      Icon(Icons.photo_library, size: 25, color: MColor.primaryNavy),
                      Text('Gallery'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Validate form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (txtUserName.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter username',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (txtMobile.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter phone number',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  // Update user profile
  Future<void> updateProfile() async {
    try {
      isLoading.value = true;
      final userId = user.value?.userId ?? '';
      final fullName = txtUserName.text.trim();
      final phoneNumber = txtMobile.text.trim();
      final imagePath = selectedImagePath.value;
      // Create FormData manually
      final formData = FormData({});

      formData.fields.addAll([
        MapEntry('UserId', userId),
        MapEntry('FullName', fullName),
        MapEntry('PhoneNumber', phoneNumber),
      ]);

      formData.files.add(
        MapEntry(
          'ProfileImage',
          MultipartFile(
            File(imagePath),
            filename: 'profile.jpg',
          ),
        ),
      );

      // 🔍 SAHAr Debug: Print FormData contents
      print(' SAHArSAHAr ⚠️ FormData Fields:');
      formData.fields.forEach((f) => print(' SAHArSAHAr 🔹 ${f.key} = ${f.value}'));

      print(' SAHArSAHAr 📷 FormData Files:');
      formData.files.forEach((f) {
        print(' SAHArSAHAr 📷 ${f.key} = ${f.value.filename}');
      });

      // Send multipart request using your updated ApiProvider
      final response = await _apiProvider.postData2('/api/User/update-user', formData);

      // 🔍 SAHAr Debug: Response
      print(' SAHArSAHAr ✅ Response Status: ${response.statusCode}');
      print(' SAHArSAHAr ✅ Response Body: ${response.bodyString}');

      if (response.statusCode == 200 || response.isOk) {
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception(response.statusText ?? 'Failed to update profile');
      }
    } catch (e) {
      print(' SAHArSAHAr ❌ Error updating profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }




  // Delete account
  Future<void> deleteAccount() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _performDeleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    // Implement delete account logic here
    try {
      isLoading.value = true;

      if (user.value?.userId != null) {
        final response = await _apiProvider.deleteData('/api/User/delete-user/${user.value!.userId}');

        if (response.isOk) {
          Get.snackbar(
            'Success',
            'Account deleted successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          await SharedPrefsService.clearUserData();
          Get.offAllNamed('/login');
        } else {
          throw Exception('Failed to delete account');
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete account: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}