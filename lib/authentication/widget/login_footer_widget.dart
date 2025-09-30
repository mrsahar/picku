import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/routes/app_routes.dart';
import 'package:pick_u/controllers/auth_controller.dart';

class LoginFooterWidget extends StatelessWidget {
  const LoginFooterWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      init: AuthController(),
      builder: (authController) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("OR"),
          const SizedBox(height: 30 - 20),
          SizedBox(
            width: double.infinity,
            child: Obx(() => OutlinedButton.icon(
              icon: authController.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LineAwesomeIcons.google_plus),
              onPressed: authController.isLoading
                  ? null
                  : () => authController.signInWithGoogle(),
              label: Text(
                authController.isLoading
                    ? "Signing in..."
                    : "Sign in With Google"
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: authController.isLoading
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
              ),
            )),
          ),
          const SizedBox(height: 30 - 20),
          TextButton(
            onPressed: () {
              Get.toNamed(AppRoutes.SIGNUP_SCREEN);
              //Get.to(() => const SignupScreen());
            },
            child: Text.rich(
              TextSpan(
                  text: "Don't Have An Account? ",
                  style: Theme.of(context).textTheme.bodySmall,
                  children: const [
                    TextSpan(text: "Signup", style: TextStyle(color: Colors.blue))
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}