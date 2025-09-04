import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/authentication/login_screen.dart';
import 'package:pick_u/authentication/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var height = mediaQuery.size.height;
    var brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image(
                image: isDarkMode
                    ? const AssetImage("assets/img/only_logo.png")
                    : const AssetImage("assets/img/logo.png"),
                height: height * 0.6),
            Column(
              children: [
                Text("Hello ji kasy hu ",
                    style: Theme.of(context).textTheme.titleLarge),
                Text("May bhi thek hu ready hu ",
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                          Get.to(() => const LoginScreen());
                    },
                    child: Text("login".toUpperCase()),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => const SignupScreen());
                    },
                    child: Text("Signup".toUpperCase()),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
