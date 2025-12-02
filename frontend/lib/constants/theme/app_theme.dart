import 'package:flutter/material.dart';

class AppTheme {
  //light theme colors
  static const Color cream = Color(0xFFFFF6E0);
  static const Color teal = Color(0xFF779792);
  static const Color tealShadow = Color(0xFF5B7B76);
  static const Color sage = Color(0xFFA5B49D);
  static const Color coral = Color(0xFFC66859);
  static const Color black = Color(0xFF000000);

  //dark theme colors
  static const Color darkCream = Color(0xFF2E2B26);
  static const Color darkTeal = Color(0xFF4A6563);
  static const Color darkTealShadow = Color(0xFF374B4A);
  static const Color darkSage = Color(0xFF6E7F73);
  static const Color darkCoral = Color(0xFF8C4A42);
  static const Color darkBlack = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: sage,
        onPrimary: Colors.white,

        secondary: teal,
        onSecondaryContainer: black,
        shadow: tealShadow,

        tertiary: cream,
        onTertiary: black,

        error: coral,
        onError: Colors.white,

        errorContainer: coral,
        onErrorContainer: Colors.white,

        surface: Colors.white,
        onSurface: black,
      ),
      useMaterial3: true,
      fontFamily: "BowlbyOneSC",
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: darkSage,
        onPrimary: Colors.black,

        secondary: darkTeal,
        onSecondaryContainer: darkBlack,
        shadow: darkTealShadow,

        tertiary: darkCream,
        onTertiary: Colors.black,

        error: darkCoral,
        onError: Colors.black,

        errorContainer: darkCoral,
        onErrorContainer: Colors.black,

        surface: darkBlack,
        onSurface: Colors.white,
      ),
      useMaterial3: true,
      fontFamily: "BowlbyOneSC",
    );
  }
}
