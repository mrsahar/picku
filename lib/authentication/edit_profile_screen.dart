import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/controllers/edit_profile_controller.dart';
import 'package:pick_u/widget/picku_appbar.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EditProfileController>();

    return Scaffold(
        appBar: PickUAppBar(
          title: "Edit Profile",
          onBackPressed: () {
            Get.back();
          },
        ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // -- IMAGE with ICON
              Obx(() => Stack(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: controller.getProfileImageWidget(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => controller.showImagePickerOptions(),
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.amberAccent,
                        ),
                        child: const Icon(
                          LineAwesomeIcons.camera_solid,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 50),

              // -- Form Fields
              Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.txtUserName,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LineAwesomeIcons.user_check_solid),
                        labelText: "Enter Username",
                        hintText: "Username",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.txtMobile,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LineAwesomeIcons.phone_solid),
                        labelText: "Enter Phone number",
                        hintText: "Phone Number",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // -- Form Submit Button
                    Obx(() => ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, // Add this line
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.updateProfile(),
                      label: controller.isLoading.value
                          ? const Text("Updating...")
                          : Text(
                        "Update Profile".toUpperCase(),
                      ),
                      icon: controller.isLoading.value
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(LineAwesomeIcons.edit),
                    )),
                    const SizedBox(height: 20),

                    // -- Created Date and Delete Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Want to delete your account?",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.deleteAccount(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            elevation: 0,
                            foregroundColor: Colors.red,
                            shape: const StadiumBorder(),
                            side: BorderSide.none,
                            minimumSize: const Size(80, 32), // Makes button smaller
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          ),
                          child: const Text("Delete", style: TextStyle(fontSize: 12)),
                        )),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
