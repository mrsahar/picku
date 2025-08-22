import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pick_u/utils/profile_widget_menu.dart';

import 'edit_profile_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){} ,
        icon: const Icon(LineAwesomeIcons.angle_left_solid)),
        title: Text("Profile",
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,),),
        actions: [IconButton(onPressed: () {}, icon: Icon(context.isDarkMode ? LineAwesomeIcons.sun : LineAwesomeIcons.moon))],
      ),
      body: SingleChildScrollView(
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
                        borderRadius: BorderRadius.circular(100), child: const Image(image: AssetImage("assets/img/u2.png"))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Sharjeel Ahmeed",  style: TextStyle(fontSize: 16)),
              const Text("+92443355433", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Get.to(() => const EditProfileScreen());
                },
                label: Text("Edit Profile".toUpperCase()),
                icon: const Icon(LineAwesomeIcons.edit),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.black12,),
              const SizedBox(height: 10),

              /// -- MENU
              ProfileMenuWidget(title: 'Your profile', icon: LineAwesomeIcons.user_solid, onPress: () {}),
              ProfileMenuWidget(title: 'Notification', icon: LineAwesomeIcons.bell_solid, onPress: () {}),
              ProfileMenuWidget(title: 'Your Rides', icon: LineAwesomeIcons.car_side_solid, onPress: () {}),
              ProfileMenuWidget(title: 'Pre-Booked Rides', icon: LineAwesomeIcons.address_book_solid, onPress: () {}),
              ProfileMenuWidget(title: 'Settings', icon: LineAwesomeIcons.cog_solid, onPress: () {}),
              ProfileMenuWidget(title: 'Cars', icon: LineAwesomeIcons.car_solid, onPress: () {}),
              ProfileMenuWidget(title: 'Help Center', icon: LineAwesomeIcons.broadcast_tower_solid, onPress: () {}),
              ProfileMenuWidget(title: 'Privacy Policy', icon: LineAwesomeIcons.question_circle_solid, onPress: () {}),
              const Divider(color: Colors.black12,),
              const SizedBox(height: 10),
              ProfileMenuWidget(title: "Information", icon: LineAwesomeIcons.info_solid, onPress: () {}),
              ProfileMenuWidget(
                  title: "Logout",
                  icon: LineAwesomeIcons.sign_out_alt_solid,
                  textColor: Colors.red,
                  endIcon: false,
                  onPress: () {
                    // Get.defaultDialog(
                    //   title: "LOGOUT",
                    //   titleStyle: const TextStyle(fontSize: 20),
                    //   content: const Padding(
                    //     padding: EdgeInsets.symmetric(vertical: 15.0),
                    //     child: Text("Are you sure, you want to Logout?"),
                    //   ),
                    //   confirm: Expanded(
                    //     child: ElevatedButton(
                    //       onPressed: () => AuthenticationRepository.instance.logout(),
                    //       style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, side: BorderSide.none),
                    //       child: const Text("Yes"),
                    //     ),
                    //   ),
                    //   cancel: OutlinedButton(onPressed: () => Get.back(), child: const Text("No")),
                    // );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
