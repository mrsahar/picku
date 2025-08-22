import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/routes/app_routes.dart';

class SignUpFooterWidget extends StatelessWidget {
  const SignUpFooterWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("OR"),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LineAwesomeIcons.google_plus),
            label: Text("Sign In With Google".toUpperCase()),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.toNamed(AppRoutes.LOGIN_SCREEN);
          },
          child: Text.rich(TextSpan(children: [
            TextSpan(
              text: "Already Have AnAccount? ",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextSpan(text: "Login".toUpperCase())
          ])),
        )
      ],
    );
  }
}