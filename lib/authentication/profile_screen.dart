import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/routes/app_routes.dart';
import 'package:pick_u/utils/profile_widget_menu.dart';
import 'edit_profile_screen.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: Text(
          "Profile",
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(context.isDarkMode ? LineAwesomeIcons.sun : LineAwesomeIcons.moon),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.userProfile.value == null) {
          return const Center(
            child: Text('Failed to load profile'),
          );
        }

        final user = controller.userProfile.value!;

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// -- IMAGE
                Stack(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Obx(() {
                          if (controller.hasProfileImage) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage: MemoryImage(controller.profileImage.value!),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 50,
                              child: Icon(Icons.person, size: 50),
                            );
                          }
                        }),
                      ),
                    ),
                    // Loading indicator for image
                    if (controller.isImageLoading.value)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  user.phoneNumber,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Get.toNamed(
                      AppRoutes.editProfile,
                      arguments: controller.userProfile.value,
                    );
                    if (result == true) {
                      controller.refreshProfile();
                    }
                  },
                  label: Text("Edit Profile".toUpperCase()),
                  icon: const Icon(LineAwesomeIcons.edit),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.black12),
                const SizedBox(height: 10),

                /// -- MENU
                ProfileMenuWidget(
                  title: 'Your profile',
                  icon: LineAwesomeIcons.user_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: 'Notification',
                  icon: LineAwesomeIcons.bell_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: 'Your Rides',
                  icon: LineAwesomeIcons.car_side_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: 'Pre-Booked Rides',
                  icon: LineAwesomeIcons.address_book_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: 'Settings',
                  icon: LineAwesomeIcons.cog_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: 'Cars',
                  icon: LineAwesomeIcons.car_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: 'Help Center',
                  icon: LineAwesomeIcons.broadcast_tower_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: 'Privacy Policy',
                  icon: LineAwesomeIcons.question_circle_solid,
                  onPress: () {},
                ),
                const Divider(color: Colors.black12),
                const SizedBox(height: 10),
                ProfileMenuWidget(
                  title: "Information",
                  icon: LineAwesomeIcons.info_solid,
                  onPress: () {},
                ),
                ProfileMenuWidget(
                  title: "Logout",
                  icon: LineAwesomeIcons.sign_out_alt_solid,
                  textColor: Colors.red,
                  endIcon: false,
                  onPress: () => controller.logout(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
