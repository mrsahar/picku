import 'package:flutter/material.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.endIcon = true,
    this.textColor,
  });

  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define colors for dark and light themes
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final defaultTextColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? MColor.warning : Colors.black;

    return Material(
      color: bgColor, // Set background color for ripple effect
      child: InkWell(
        onTap: onPress,
        splashColor: iconColor.withValues(alpha:0.2), // Customize ripple color
        borderRadius: BorderRadius.circular(8), // Optional: Rounded ripple
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: textColor?.withValues(alpha:0.1) ?? iconColor.withValues(alpha:0.1),
              ),
              child: Icon(icon, color: textColor ?? iconColor),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: textColor ?? defaultTextColor,
              ),
            ),
            trailing: endIcon
                ? Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.grey.withValues(alpha:0.1),
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 14.0,
                color: Colors.grey,
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }
}

