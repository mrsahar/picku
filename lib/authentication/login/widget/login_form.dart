import 'package:flutter/material.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:pick_u/authentication/otp_screen.dart';
import 'package:pick_u/authentication/reset_password/reset_password_screen.dart';
import 'package:pick_u/common/extension.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  FlCountryCodePicker countryCodePicker = const FlCountryCodePicker();
  TextEditingController txtMobile = TextEditingController();

  late CountryCode countryCode;
  @override
  void initState() {
    super.initState();

    countryCode = countryCodePicker.countryCodes
        .firstWhere((element) => element.name == "Pakistan");
  }

  @override
  Widget build(BuildContext context) {

    return Form(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20 - 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 25,
            ),
            InkWell(
              onTap: () async {
                final code = await countryCodePicker.showPicker(
                    context: context);

                if (code != null) {
                  countryCode = code;
                  setState(() {});
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                width: double.maxFinite,
                height: 60,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(width: 1),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12, blurRadius: .2)
                    ]),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 30,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: countryCode.flagImage(
                            fit: BoxFit.cover,
                          )),
                    ),
                    const SizedBox(width: 10,),
                    Expanded(
                      child: Text(
                        "${countryCode.name.toUpperCase()} ( ${countryCode.dialCode} )",
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const SizedBox(height: 30 - 20),
            TextFormField(
              keyboardType : TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.fingerprint),
                labelText: "Enter Mobile Number",
                hintText: "Number",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.remove_red_eye_sharp),
                ),
              ),
            ),
            const SizedBox(height: 30 - 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () {
                    context.push(const ResetPasswordScreen());
                  }, child: const Text("Forget Password?")),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(const OTPScreen());
                },
                child: Text("Login".toUpperCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}