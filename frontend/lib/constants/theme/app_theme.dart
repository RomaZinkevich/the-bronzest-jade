import 'package:flutter/material.dart';

class AppTheme {
  //light theme colors
  static const Color cream = Color(0xFFFFF6E0);
  static const Color teal = Color(0xFF779792);
  static const Color tealShadow = Color(0xFF5B7B76);
  static const Color sage = Color(0xFFA5B49D);
  static const Color coral = Color(0xFFC66859);
  static const Color black = Color(0xFF000000);

  // dark theme colors
  static const Color darkCream = Color(0xFF0A0A0A);
  static const Color darkTeal = Color(0xFF1A2423);
  static const Color darkTealShadow = Color(0xFF111818);
  static const Color darkSage = Color(0xFF1C1F1A);
  static const Color darkCoral = Color(0xFF934340);
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
        onPrimary: Colors.black,

        secondary: darkTeal,
        onSecondaryContainer: darkBlack,
        shadow: darkTealShadow,

        tertiary: Color(0xFFE6DFC9),
        onTertiary: darkBlack,

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
