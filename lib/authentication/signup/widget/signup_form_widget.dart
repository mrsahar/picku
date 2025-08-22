import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class SignUpFormWidget extends StatelessWidget {
  const SignUpFormWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("UserName"),
                  prefixIcon: Icon(LineAwesomeIcons.user)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Email"), prefixIcon: Icon(LineAwesomeIcons.envelope)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Phone No"), prefixIcon: Icon(LineAwesomeIcons.phone_solid)),
            ),
            const SizedBox(height:20),
            const SizedBox(height:10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text("Signup".toUpperCase()),
              ),
            )
          ],
        ),
      ),
    );
  }
}