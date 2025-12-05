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
  static const Color darkCream = Color(0xFF0D0D0D);
  static const Color darkTeal = Color(0xFF5A9B94);
  static const Color darkTealShadow = Color(0xFF3F7075);
  static const Color darkSage = Color(0xFF8FA082);
  static const Color darkCoral = Color(0xFFE07A6A);
  static const Color darkBlack = Color(0xFFF5F5F5);

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
        onPrimary: Colors.black,

        secondary: darkTeal,
        onSecondaryContainer: Colors.white,
        shadow: darkTealShadow,

        tertiary: Color(0xFF1F1F1F),
        onTertiary: Colors.white,

        error: darkCoral,
        onError: Colors.black,

        errorContainer: darkCoral,
        onErrorContainer: Colors.black,

        surface: Color(0xFF181818),
        onSurface: darkBlack,

        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkCream,
      useMaterial3: true,
      fontFamily: "BowlbyOneSC",
    );
  }
}
