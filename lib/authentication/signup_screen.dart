import 'package:flutter/material.dart';
import 'package:pick_u/authentication/widget/signup_footer_widget.dart';
import 'package:pick_u/authentication/widget/signup_form_widget.dart';
import 'package:pick_u/authentication/widget/signup_header_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        body: SingleChildScrollView(
          child: Container(
            height: size.height,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FormHeaderWidget(
                  image: "assets/img/logo.png",
                  title: "Create Account",
                  subTitle: "Fill your information below or register with your social account.",
                  imageHeight: 0.15,
                ),
                SignUpFormWidget(),
                SignUpFooterWidget(),
              ],
            ),
          ),
        ),
    );
  }
}
