import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/otp_controller.dart';


class OTPScreen extends StatelessWidget {
  const OTPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OTPController>();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/img/logo.png"),
            const SizedBox(height: 40.0),
            Text("Verify Code".toUpperCase(), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 40.0),

            // Dynamic text showing the email
            Obx(() => Text(
              controller.email.value.isNotEmpty
                  ? "Please enter the code we just sent to ${controller.email.value}"
                  : "Please enter the code we just sent to your email",
              textAlign: TextAlign.center,
            )),

            const SizedBox(height: 20.0),

            // OTP TextField connected to controller
            OtpTextField(
              focusedBorderColor: const Color(0xFFFFC900),
              mainAxisAlignment: MainAxisAlignment.center,
              numberOfFields: 6,
              fillColor: Colors.black.withValues(alpha:0.1),
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

            const SizedBox(height: 20.0),

            // Updated button with loading state and controller action
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : () {
                  controller.verifyOTP();
                },
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify OTP"),
              ),
            )),

            const SizedBox(height: 20.0),

            // Add Resend OTP button
            TextButton(
              onPressed: () {
                controller.resendOTP();
              },
              child: const Text("Resend OTP"),
            ),
          ],
        ),
      ),
    );
  }
}