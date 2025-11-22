import 'package:flutter/material.dart';
import 'package:guess_who/constants/theme/app_theme.dart';
import 'package:guess_who/constants/utils/responsive_wrapper.dart';
import 'package:guess_who/screens/mainmenuscreen.dart';

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
      builder: (context, child) {
        return ResponsiveWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
