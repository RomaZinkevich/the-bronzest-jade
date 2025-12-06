import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guess_who/providers/settings_provider.dart';
import 'package:guess_who/widgets/common/retro_button.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';

class AccountScreen extends StatelessWidget {
  final String playerName;
  final String playerId;
  final String profilePicture;

  const AccountScreen({
    super.key,
    required this.playerName,
    required this.playerId,
    this.profilePicture = "assets/icons/default_user.png",
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          body: Stack(
            children: [
              SizedBox.expand(
                child: Image.asset(
                  "assets/main_menu.png",
                  fit: BoxFit.cover,
                  color: settings.isDarkMode
                      ? Colors.black.withOpacity(0.5)
                      : null,
                  colorBlendMode: settings.isDarkMode ? BlendMode.darken : null,
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          RetroIconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icons.arrow_back_rounded,
                            iconSize: 24,
                            padding: 12,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.tertiary,
                            iconColor: Theme.of(context).colorScheme.secondary,
                            tooltip: "Back",
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor: Colors.transparent,
                                  foregroundImage: AssetImage(profilePicture),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Player info
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  playerName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Action buttons
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Change name feature coming soon!",
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  "CHANGE NAME",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(1, 1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              RetroButton(
                                text: "SIGN UP",
                                fontSize: 16,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 16,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                foregroundColor: Colors.white,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Sign up feature coming soon!",
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              RetroButton(
                                text: "LOG IN",
                                fontSize: 16,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 16,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Log in feature coming soon!",
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
