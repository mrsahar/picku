import 'package:flutter/material.dart';
import 'package:pick_u/utils/theme/text_theme.dart';
import 'mcolors.dart';

class MAppTheme {
  MAppTheme._();

  // Using MColor class for consistency
  static Color get primaryNavyColor => MColor.primaryNavy;
  static Color get trackingOrangeColor => MColor.trackingOrange;
  static Color get whiteColor => MColor.white;

  static ThemeData lightTheme = ThemeData(
    primarySwatch: MaterialColor(0xFF1A2A44, {
      50: Color(0xFFE3E7ED),
      100: Color(0xFFBAC4D3),
      200: Color(0xFF8C9DB6),
      300: Color(0xFF5E7699),
      400: Color(0xFF3C5983),
      500: MColor.primaryNavy, // Using MColor
      600: Color(0xFF17253D),
      700: Color(0xFF131F34),
      800: Color(0xFF0F192B),
      900: Color(0xFF080F1C),
    }),
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MColor.primaryNavy,
      brightness: Brightness.light,
    ).copyWith(
      primary: MColor.primaryNavy,
      secondary: MColor.trackingOrange,
      surface: MColor.white,
      onPrimary: MColor.white,
      onSecondary: MColor.white,
      onSurface: MColor.primaryNavy,
    ),
    scaffoldBackgroundColor: MColor.mainBg,
    appBarTheme: AppBarTheme(
      backgroundColor: MColor.primaryNavy,
      foregroundColor: MColor.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: MColor.white,
      elevation: 2,
      margin: const EdgeInsets.all(8),
    ),
    dividerTheme: DividerThemeData(
      color: MColor.lightGrey,
      thickness: 0.7,
    ),
    textTheme: MTextTheme.lightTextTheme,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: MColor.trackingOrange,
      foregroundColor: MColor.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: MColor.white,
        backgroundColor: MColor.primaryNavy,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MColor.primaryNavy,
        side: BorderSide(color: MColor.primaryNavy, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MColor.primaryNavy,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MColor.lightGrey,
      hintStyle: TextStyle(color: MColor.mediumGrey),
      labelStyle: TextStyle(color: MColor.primaryNavy),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: MColor.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: MColor.primaryNavy, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: MColor.lightGrey),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: MColor.white,
      selectedItemColor: MColor.primaryNavy,
      unselectedItemColor: MColor.mediumGrey,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(
      color: MColor.primaryNavy,
      size: 24,
    ),
    // Special theme for tracking elements
    chipTheme: ChipThemeData(
      backgroundColor: MColor.trackingOrange.withOpacity(0.1),
      labelStyle: TextStyle(color: MColor.primaryNavy),
      side: BorderSide(color: MColor.trackingOrange),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primarySwatch: MaterialColor(0xFF1A2A44, {
      50: Color(0xFFE3E7ED),
      100: Color(0xFFBAC4D3),
      200: Color(0xFF8C9DB6),
      300: Color(0xFF5E7699),
      400: Color(0xFF3C5983),
      500: Color(0xFF1A2A44),
      600: Color(0xFF17253D),
      700: Color(0xFF131F34),
      800: Color(0xFF0F192B),
      900: Color(0xFF080F1C),
    }),
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MColor.primaryNavy,
      brightness: Brightness.dark,
    ).copyWith(
      primary: MColor.primaryNavy,
      secondary: MColor.trackingOrange,
      surface: MColor.darkGrey,
      onPrimary: MColor.white,
      onSecondary: MColor.white,
      onSurface: MColor.white,
    ),
    scaffoldBackgroundColor: MColor.darkBg,
    appBarTheme: AppBarTheme(
      backgroundColor: MColor.primaryNavy,
      foregroundColor: MColor.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: MColor.darkGrey,
      elevation: 4,
      margin: const EdgeInsets.all(8),
    ),
    dividerTheme: DividerThemeData(
      color: MColor.mediumGrey,
      thickness: 0.7,
    ),
    textTheme: MTextTheme.darkTextTheme,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: MColor.trackingOrange,
      foregroundColor: MColor.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: MColor.white,
        backgroundColor: MColor.primaryNavy,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MColor.white,
        side: BorderSide(color: MColor.primaryNavy.withOpacity(0.8), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MColor.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MColor.darkGrey,
      hintStyle: TextStyle(color: MColor.mediumGrey),
      labelStyle: TextStyle(color: MColor.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: MColor.mediumGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: MColor.primaryNavy, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: MColor.mediumGrey),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: MColor.darkGrey,
      selectedItemColor: MColor.trackingOrange,
      unselectedItemColor: MColor.mediumGrey,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(
      color: MColor.white,
      size: 24,
    ),
    // Special theme for tracking elements in dark mode
    chipTheme: ChipThemeData(
      backgroundColor: MColor.trackingOrange.withOpacity(0.2),
      labelStyle: TextStyle(color: MColor.white),
      side: BorderSide(color: MColor.trackingOrange),
    ),
  );

  // Helper method to get tracking orange color for car icons/buttons
  static Color getTrackingColor() => MColor.trackingOrange;

  // Helper method to get primary navy color
  static Color getPrimaryNavy() => MColor.primaryNavy;
}

// Extension for easy access to tracking colors in widgets
extension TrackingColors on BuildContext {
  Color get trackingOrange => MColor.trackingOrange;
  Color get primaryNavy => MColor.primaryNavy;
}
