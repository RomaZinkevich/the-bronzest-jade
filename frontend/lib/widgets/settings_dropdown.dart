import 'package:flutter/material.dart';
import 'package:guess_who/services/audio_manager.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsDropdown extends StatelessWidget {
  const SettingsDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return PopupMenuButton<String>(
          tooltip: 'Settings',
          icon: Icon(
            Icons.settings_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.tertiary,
            shadows: [
              Shadow(
                color: Theme.of(context).colorScheme.shadow,
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          color: Theme.of(context).colorScheme.tertiary,
          constraints: BoxConstraints(minWidth: 60, maxWidth: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
          offset: const Offset(0, 50),
          itemBuilder: (BuildContext context) {
            AudioManager().playPopupSfx();
            return [
              PopupMenuItem<String>(
                value: 'theme',
                onTap: () {
                  AudioManager().playPopupSfx();
                  settings.toggleTheme();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Center(
                    child: Icon(
                      settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'sound',
                onTap: () {
                  AudioManager().playPopupSfx();

                  settings.toggleSound();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Center(
                    child: Icon(
                      settings.isSoundEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'music',
                onTap: () {
                  AudioManager().playPopupSfx();
                  settings.toggleMusic();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Center(
                    child: Icon(
                      settings.isMusicEnabled
                          ? Icons.music_note
                          : Icons.music_off_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ];
          },
        );
      },
    );
  }
}
