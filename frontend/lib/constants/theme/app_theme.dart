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
  static const Color darkCream = Color(0xFF1A1A1A);
  static const Color darkTeal = Color(0xFF4A7873);
  static const Color darkTealShadow = Color(0xFF3A5E5B);
  static const Color darkSage = Color(0xFF7B8C6F);
  static const Color darkCoral = Color(0xFFB85A4A);
  static const Color darkBlack = Color(0xFFE0E0E0);

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

        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      fontFamily: "BowlbyOneSC",
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: darkSage,
        onPrimary: darkBlack,

        secondary: darkTeal,
        onSecondaryContainer: darkBlack,
        shadow: darkTealShadow,

        tertiary: Color(0xFF2A2A2A),
        onTertiary: darkBlack,

        error: darkCoral,
        onError: darkBlack,

        errorContainer: darkCoral,
        onErrorContainer: darkBlack,

        surface: Color(0xFF121212),
        onSurface: darkBlack,

        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkCream,
      useMaterial3: true,
      fontFamily: "BowlbyOneSC",
    );
  }
}
