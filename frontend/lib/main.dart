import 'package:flutter/material.dart';
import 'package:guess_who/constants/theme/app_theme.dart';
import 'package:guess_who/constants/utils/responsive_wrapper.dart';
import 'package:guess_who/providers/settings_provider.dart';
import 'package:guess_who/screens/mainmenuscreen.dart';
import 'package:guess_who/services/audio_manager.dart';
import 'package:guess_who/services/deep_link_service.dart';
import 'package:provider/provider.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioManager().init();
  await DeepLinkService().initialize();

  final isAuthenticated = await AuthService.isAuthenticated();
  if (!isAuthenticated) {
    try {
      final response = await ApiService.createGuestUser();
      await AuthService.saveAuthData(
        token: response["token"],
        userId: response["userId"],
        username: response["username"],
        isGuest: true,
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
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: "Guess Who?",
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const ResponsiveWrapper(child: MainMenuScreen()),
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) =>
                    const ResponsiveWrapper(child: MainMenuScreen()),
              );
            },

            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) =>
                    const ResponsiveWrapper(child: MainMenuScreen()),
              );
            },
          );
        },
      ),
    );
  }
}
