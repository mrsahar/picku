import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/common/extension.dart';
import 'package:pick_u/taxi/main/search/search_location.dart';

Widget buildTag(String label, BuildContext context, bool isDark) {
  final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]; // Background color
  final borderColor = isDark ? Colors.orangeAccent : Colors.amberAccent; // Border color
  final textColor = isDark ? Colors.white : Colors.black; // Text color
  final iconColor = isDark ? Colors.amberAccent : Colors.black; // Icon color

  return Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor, // Background color changes dynamically
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: borderColor), // Border changes dynamically
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => const SearchLocation());// Ensure SearchLocation is defined
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LineAwesomeIcons.map_marker_alt_solid,
              size: 16.0,
              color: iconColor, // Icon color changes dynamically
            ),
            const SizedBox(width: 3), // Space between icon and text
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: textColor, // Text color changes dynamically
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
