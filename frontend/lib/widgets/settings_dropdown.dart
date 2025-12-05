import 'package:flutter/material.dart';
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
                color: Colors.black54,
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          color: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
          offset: const Offset(0, 50),
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'theme',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 24,
                    ),
                    Switch(
                      value: settings.isDarkMode,
                      onChanged: (value) {
                        settings.toggleTheme();
                      },
                      activeThumbColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'sound',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      settings.isSoundEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 24,
                    ),
                    Switch(
                      value: settings.isSoundEnabled,
                      onChanged: (value) {
                        settings.toggleSound();
                      },
                      activeThumbColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ];
          },
          onSelected: (String value) {
            // Handle menu item selection if needed
            switch (value) {
              case 'theme':
                // Theme toggle is handled by the switch
                break;
              case 'sound':
                // Sound toggle is handled by the switch
                break;
            }
          },
        );
      },
    );
  }
}
