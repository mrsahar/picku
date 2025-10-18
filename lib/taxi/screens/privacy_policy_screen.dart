import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/widget/picku_appbar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PickUAppBar(
          title: "Privacy Policy",
          onBackPressed: () {
            Get.back();
          },
        ),
      body: const Center(
        child: Text(
          "No privacy policy available yet",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
