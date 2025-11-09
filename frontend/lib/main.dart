import 'package:flutter/material.dart';
import 'package:guess_who/mainmenuscreen.dart';
import 'package:guess_who/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guess Who?',
      theme: AppTheme.lightTheme,
      home: const MainMenuScreen(),
    );
  }
}
