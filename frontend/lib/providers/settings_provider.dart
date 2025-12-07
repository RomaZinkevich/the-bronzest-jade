import 'package:flutter/material.dart';
import 'package:guess_who/services/audio_manager.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isMusicEnabled => _isMusicEnabled;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    AudioManager().toggleSfx();

    notifyListeners();
  }

  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    AudioManager().toggleMusic();

    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
