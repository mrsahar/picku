import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/login_controller.dart';
import 'package:pick_u/routes/app_routes.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Add safety check to prevent accessing disposed controller
    try {
      final controller = Get.find<LoginController>();

      return Form(
      key: controller.formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20 - 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 25,
            ),
            // Email Input Field
            TextFormField(
              controller: controller.emailController,
              validator: controller.validateEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email),
                labelText: "Enter Email Address",
                hintText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            // Password Input Field
            Obx(() => TextFormField(
              controller: controller.passwordController,
              validator: controller.validatePassword,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                labelText: "Enter Password",
                hintText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 30 - 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.forgotPasswordScreen);
                  },
                  child: const Text("Forgot Password?")),
            ),
            // Login Button (connected to controller with loading state)
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                  controller.login(context);
                },
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Login".toUpperCase()),
              ),
            )),
          ],
        ),
      ),
    );
    } catch (e) {
      // If controller is not found or has been disposed, return empty widget
      print('LoginForm Error: Controller not found or disposed - $e');
      return const SizedBox.shrink();
    }
  }
}