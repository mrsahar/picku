// authentication/reset_password_new_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get/get.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ResetPasswordController>();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset("assets/img/logo.png"),
              const SizedBox(height: 40.0),
              Text("Reset Password".toUpperCase(), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 40.0),

              // Dynamic text showing the email
              Obx(() => Text(
                controller.email.value.isNotEmpty
                    ? "Enter the OTP sent to ${controller.email.value} and your new password"
                    : "Enter the OTP sent to your email and your new password",
                textAlign: TextAlign.center,
              )),

              const SizedBox(height: 20.0),

              // OTP TextField connected to controller
              OtpTextField(
                focusedBorderColor: const Color(0xFFFFC900),
                mainAxisAlignment: MainAxisAlignment.center,
                numberOfFields: 6,
                fillColor: Colors.black.withOpacity(0.1),
                filled: true,
                onSubmit: (code) {
                  // Store the complete OTP in controller
                  controller.setCompleteOTP(code);
                  print("OTP is => $code");
                },
                onCodeChanged: (code) {
                  // Update OTP as user types
                  controller.setCompleteOTP(code);
                },
              ),

              const SizedBox(height: 30.0),

              // New Password Field
              Obx(() => TextFormField(
                controller: controller.newPasswordController,
                obscureText: !controller.isNewPasswordVisible.value,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: const Text("New Password"),
                  hintText: "Enter new password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: controller.toggleNewPasswordVisibility,
                    icon: Icon(
                      controller.isNewPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 20.0),

              // Confirm Password Field
              Obx(() => TextFormField(
                controller: controller.confirmPasswordController,
                obscureText: !controller.isConfirmPasswordVisible.value,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: const Text("Confirm Password"),
                  hintText: "Confirm new password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: controller.toggleConfirmPasswordVisibility,
                    icon: Icon(
                      controller.isConfirmPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 30.0),

              // Reset Password button with loading state
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.resetPassword,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('RESET PASSWORD'),
                ),
              )),

              const SizedBox(height: 20.0),

              // Resend OTP button
              TextButton(
                onPressed: () {
                  controller.resendOTP();
                },
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}