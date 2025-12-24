import 'package:flutter/material.dart';

class MColor {
  // Background colors
  static Color get mainBg => const Color(0xFFFFFFFF);
  static Color get lightBg => const Color(0xFFFFFFFF);//// White background
  static Color get darkBg => const Color(0xFF121212); // Dark background for dark theme

  // Primary colors
  static Color get primaryNavy => const Color(0xFF1A2A44); // Deep navy blue for headers, buttons, accents
  static Color get trackingOrange => const Color(0xFF1A2A44); // Orange for tracking car icon/button

  // Muted amber — darker tone for dark backgrounds
  static Color get warning => const Color(0xFFFFB300); // Deep amber / gold
  static Color get danger => const Color(0xFFB71C1C); // Dark crimson red
  static Color get success => const Color(0xFF2E7D32); // Dark green for success states

  // Additional colors for better theme support
  static Color get white => const Color(0xFFFFFFFF);
  static Color get lightGrey => const Color(0xFFF5F5F5);
  static Color get mediumGrey => const Color(0xFF9E9E9E);
  static Color get darkGrey => const Color(0xFF424242);
}