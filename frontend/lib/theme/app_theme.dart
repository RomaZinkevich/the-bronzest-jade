import 'package:flutter/material.dart';

class AppTheme {
  static const Color cream = Color(0xFFFFF6E0);
  static const Color teal = Color(0xFF779792);
  static const Color sage = Color(0xFFA5B49D);
  static const Color coral = Color(0xFFC66859);
  static const Color black = Color(0xFF000000);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: sage,
        onPrimary: Colors.white,

        secondary: teal,
        onSecondaryContainer: black,

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
}
