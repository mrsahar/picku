import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/controllers/signup_controller.dart';

class SignUpFormWidget extends StatelessWidget {
  const SignUpFormWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignUpController>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username Field
          Obx(() => TextFormField(
            controller: controller.fullNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.fullNameError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.fullNameError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.fullNameError.value.isEmpty
                      ? Colors.blue
                      : Colors.red,
                ),
              ),
              label: Text(
                "UserName",
                style: TextStyle(
                  color: controller.fullNameError.value.isEmpty
                      ? Colors.grey[700]
                      : Colors.red,
                ),
              ),
              prefixIcon: Icon(
                LineAwesomeIcons.user,
                color: controller.fullNameError.value.isEmpty
                    ? Colors.grey[600]
                    : Colors.red,
              ),
              errorText: controller.fullNameError.value.isEmpty
                  ? null
                  : controller.fullNameError.value,
              errorStyle: const TextStyle(color: Colors.red),
            ),
            onChanged: (value) {
              // Clear error when user starts typing
              if (controller.fullNameError.value.isNotEmpty) {
                controller.clearFullNameError();
              }
            },
          )),

          const SizedBox(height: 20),

          // Email Field
          Obx(() => TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.emailError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.emailError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.emailError.value.isEmpty
                      ? Colors.blue
                      : Colors.red,
                ),
              ),
              label: Text(
                "Email",
                style: TextStyle(
                  color: controller.emailError.value.isEmpty
                      ? Colors.grey[700]
                      : Colors.red,
                ),
              ),
              prefixIcon: Icon(
                LineAwesomeIcons.envelope,
                color: controller.emailError.value.isEmpty
                    ? Colors.grey[600]
                    : Colors.red,
              ),
              errorText: controller.emailError.value.isEmpty
                  ? null
                  : controller.emailError.value,
              errorStyle: const TextStyle(color: Colors.red),
            ),
            onChanged: (value) {
              // Clear error when user starts typing
              if (controller.emailError.value.isNotEmpty) {
                controller.clearEmailError();
              }
            },
          )),

          const SizedBox(height: 20),

          // Phone Field
          Obx(() => TextFormField(
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.phoneError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.phoneError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.phoneError.value.isEmpty
                      ? Colors.blue
                      : Colors.red,
                ),
              ),
              label: Text(
                "Phone No",
                style: TextStyle(
                  color: controller.phoneError.value.isEmpty
                      ? Colors.grey[700]
                      : Colors.red,
                ),
              ),
              prefixIcon: Icon(
                LineAwesomeIcons.phone_solid,
                color: controller.phoneError.value.isEmpty
                    ? Colors.grey[600]
                    : Colors.red,
              ),
              errorText: controller.phoneError.value.isEmpty
                  ? null
                  : controller.phoneError.value,
              errorStyle: const TextStyle(color: Colors.red),
            ),
            onChanged: (value) {
              // Clear error when user starts typing
              if (controller.phoneError.value.isNotEmpty) {
                controller.clearPhoneError();
              }
            },
          )),

          const SizedBox(height: 20),

          // Password Field
          Obx(() => TextFormField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.passwordError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.passwordError.value.isEmpty
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: controller.passwordError.value.isEmpty
                      ? Colors.blue
                      : Colors.red,
                ),
              ),
              label: Text(
                "Password",
                style: TextStyle(
                  color: controller.passwordError.value.isEmpty
                      ? Colors.grey[700]
                      : Colors.red,
                ),
              ),
              prefixIcon: Icon(
                LineAwesomeIcons.lock_solid,
                color: controller.passwordError.value.isEmpty
                    ? Colors.grey[600]
                    : Colors.red,
              ),
              errorText: controller.passwordError.value.isEmpty
                  ? null
                  : controller.passwordError.value,
              errorStyle: const TextStyle(color: Colors.red),
            ),
            onChanged: (value) {
              // Clear error when user starts typing
              if (controller.passwordError.value.isNotEmpty) {
                controller.clearPasswordError();
              }
            },
          )),

          const SizedBox(height: 10),

          // Sign Up Button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.signUp,
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("Signup".toUpperCase()),
            ),
          ))
        ],
      ),
    );
  }
}