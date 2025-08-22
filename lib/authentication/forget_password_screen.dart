import 'package:flutter/material.dart';
import 'package:pick_u/authentication/widget/signup_header_widget.dart';

import 'package:get/get.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20 * 4),
                FormHeaderWidget(
                  image: "assets/img/logo.png",
                  title: "Forgot Password".toUpperCase(),
                  subTitle: "Enter your email to receive reset instructions", // Updated subtitle
                  crossAxisAlignment: CrossAxisAlignment.center,
                  heightBetween: 30.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Form(
                  key: controller.formKey, // ✅ Connected to controller
                  child: Column(
                    children: [
                      TextFormField(
                        controller: controller.emailController, // ✅ Connected to controller
                        validator: controller.validateEmail, // ✅ Added validation
                        keyboardType: TextInputType.emailAddress, // ✅ Changed to email input
                        decoration: const InputDecoration(
                            label: Text("Email Address"),
                            hintText: "Your Email",
                            prefixIcon: Icon(Icons.mail_outline_rounded)),
                      ),
                      const SizedBox(height: 20.0),
                      Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.forgotPassword,
                              child: controller.isLoading.value
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Send Reset Email")))),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // ✅ Added back to login button
                TextButton(
                  onPressed: controller.goBackToLogin,
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}