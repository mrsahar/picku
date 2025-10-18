import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/widget/picku_appbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PickUAppBar(
        title: "Settings",
        onBackPressed: () {
          Get.back();
        },
      ),
      body: const Center(
        child: Text(
          "No Settings yet",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
