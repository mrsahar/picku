import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart'; 
import 'package:pick_u/common/extension.dart';
import 'package:pick_u/taxi/main/main_map.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class VerifyMessageScreen extends StatefulWidget {
  const VerifyMessageScreen({super.key});

  @override
  State<VerifyMessageScreen> createState() => _VerifyMessageScreenState();
}

class _VerifyMessageScreenState extends State<VerifyMessageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/img/otp_bg.png",
            width: double.maxFinite,
            height: double.maxFinite,
            fit: BoxFit.fitWidth,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 80,
              ),
              Image.asset(
                "assets/img/logo.png",
                width: context.width * 0.7,
                fit: BoxFit.fitWidth,
              ),
              const Spacer(),
              Text(
                "Your Account\nHas Been Verified\nSuccessfully",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MColor.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold, // Optional, adjust if needed
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                   context.push(const MainMap());
                },
                child: const Icon(LineAwesomeIcons.arrow_right_solid),
              ),
              const SizedBox(
                height: 80,
              ),
            ],
          )
        ],
      ),
    );
  }
}
