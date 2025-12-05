import 'package:flutter/material.dart';
import 'package:guess_who/constants/theme/app_theme.dart';
import 'package:guess_who/constants/utils/responsive_wrapper.dart';
import 'package:guess_who/screens/mainmenuscreen.dart';
import 'package:guess_who/providers/settings_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Guess Who?',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const ResponsiveWrapper(child: MainMenuScreen()),
          );
        },
      ),
    );
  }
}
