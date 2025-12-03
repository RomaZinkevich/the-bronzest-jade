import 'package:flutter/material.dart';
import 'package:guess_who/constants/theme/app_theme.dart';
import 'package:guess_who/constants/utils/responsive_wrapper.dart';
import 'package:guess_who/screens/mainmenuscreen.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isAuthenticated = await AuthService.isAuthenticated();
  if (!isAuthenticated) {
    try {
      final response = await ApiService.createGuestUser();
      await AuthService.saveAuthData(
        token: response["token"],
        userId: response["userId"],
        username: response["username"],
      );
    } catch (e) {
      debugPrint("Failed to create guest user: $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Guess Who?",
      theme: AppTheme.lightTheme,
      home: const MainMenuScreen(),
      builder: (context, child) {
        return ResponsiveWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
