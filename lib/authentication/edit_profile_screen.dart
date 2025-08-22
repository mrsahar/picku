import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/authentication/profile_screen.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  TextEditingController txtProfile = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtMobile = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: const Icon(LineAwesomeIcons.angle_left_solid)),
        title: const Text("Edit Profile", style: TextStyle(fontSize: 16),),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // -- IMAGE with ICON
              Stack(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: const Image(image: AssetImage("assets/img/user_placeholder.png"))),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.amberAccent),
                      child: const Icon(LineAwesomeIcons.camera_solid, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // -- Form Fields
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      keyboardType : TextInputType.text,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LineAwesomeIcons.user_check_solid),
                        labelText: "Enter Username",
                        hintText: "Username",
                        border: OutlineInputBorder(),
                      ),
                    ),const SizedBox(height: 20),
                    TextFormField(
                      keyboardType : TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LineAwesomeIcons.envelope_open_solid),
                        labelText: "Enter Email Address",
                        hintText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),const SizedBox(height: 20),
                    TextFormField(
                      keyboardType : TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LineAwesomeIcons.phone_solid),
                        labelText: "Enter Phone number",
                        hintText: "Username",
                        border: OutlineInputBorder(),
                      ),
                    ),const SizedBox(height: 20),

                    // -- Form Submit Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.to(() => const EditProfileScreen());
                      },
                      label: Text("Edit Profile".toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium),
                      icon: const Icon(LineAwesomeIcons.edit),
                    ),
                    const SizedBox(height: 20),

                    // -- Created Date and Delete Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text.rich(
                          TextSpan(
                            text: "Joined ",
                            style: TextStyle(fontSize: 12),
                            children: [
                              TextSpan(
                                  text: "31 Jan 2022",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Get.to(() => const ProfileScreen());},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              elevation: 0,
                              foregroundColor: Colors.red,
                              shape: const StadiumBorder(),
                              side: BorderSide.none),
                          child: const Text("Delete"),
                        ),
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
