import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/routes/app_routes.dart';

import '../signup_screen.dart';

class LoginFooterWidget extends StatelessWidget {
  const LoginFooterWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("OR"),
        const SizedBox(height: 30 - 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(LineAwesomeIcons.google_plus),
            onPressed: () {},
            label: const Text("Signing With Google"),
          ),
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
    );
  }
}