import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:guess_who/providers/settings_provider.dart';
import 'package:guess_who/widgets/common/retro_button.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';
import 'package:guess_who/widgets/auth_popup.dart';
import 'package:guess_who/services/auth_service.dart';
import 'package:guess_who/services/api_service.dart';

class AccountScreen extends StatefulWidget {
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
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _currentUsername;
  final TextEditingController _usernameController = TextEditingController();
  bool _isEditingUsername = false;
  bool _isUpdatingUsername = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUsername() async {
    final username = await AuthService.getUsername();
    if (mounted) {
      setState(() {
        _currentUsername = username;
        _usernameController.text = username ?? widget.playerName;
      });
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    if (newUsername.trim().isEmpty || newUsername.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Username must be at least 3 characters"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isUpdatingUsername = true);

    try {
      final response = await ApiService.updateUsername(
        newUsername: newUsername.trim(),
      );

      await AuthService.saveAuthData(
        token: response["token"] ?? await AuthService.getToken() ?? "",
        userId: response["userId"] ?? await AuthService.getUserId() ?? "",
        username: response["username"],
      );

      if (mounted) {
        setState(() {
          _currentUsername = response["username"];
          _usernameController.text = response["username"];
          _isEditingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update username: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        _usernameController.text = _currentUsername ?? widget.playerName;
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingUsername = false);
      }
    }
  }

  Future<void> _copyUsernameToClipboard() async {
    final username = _currentUsername ?? widget.playerName;
    await Clipboard.setData(ClipboardData(text: username));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Username '$username' copied to clipboard!"),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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
                                  foregroundImage: AssetImage(
                                    widget.profilePicture,
                                  ),
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

                          // Player info - editable username
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
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
                                if (_isEditingUsername) ...[
                                  SizedBox(
                                    width: 150,
                                    child: TextField(
                                      controller: _usernameController,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                      ),
                                      onSubmitted: (value) {
                                        if (!_isUpdatingUsername) {
                                          _updateUsername(value);
                                        }
                                      },
                                      autofocus: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_isUpdatingUsername)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () => _updateUsername(
                                        _usernameController.text,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditingUsername = false;
                                        _usernameController.text =
                                            _currentUsername ??
                                            widget.playerName;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ),
                                ] else ...[
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditingUsername = true;
                                      });
                                    },
                                    child: Text(
                                      (_currentUsername ?? widget.playerName)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _copyUsernameToClipboard,
                                    child: Icon(
                                      Icons.copy_rounded,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Action buttons
                          Column(
                            children: [
                              RetroButton(
                                text: "SIGN UP",
                                fontSize: 16,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 16,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                onPressed: () async {
                                  final result = await AuthPopup.showSignUp(
                                    context,
                                  );
                                  if (result == true && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Account created successfully!",
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    );
                                    Navigator.pop(
                                      context,
                                    ); // Return to main menu
                                  }
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
                                onPressed: () async {
                                  final result = await AuthPopup.showLogin(
                                    context,
                                  );
                                  if (result == true && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Logged in successfully!",
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    );
                                    Navigator.pop(
                                      context,
                                    ); // Return to main menu
                                  }
                                },
                              ),

                              const SizedBox(height: 20),

                              RetroButton(
                                text: "LOGOUT",
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
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Logout"),
                                        content: const Text(
                                          "Are you sure you want to logout?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await AuthService.clearAuthData();
                                              if (mounted) {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Close dialog
                                                Navigator.pop(
                                                  context,
                                                ); // Return to main menu
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      "Logged out successfully",
                                                    ),
                                                    backgroundColor: Theme.of(
                                                      context,
                                                    ).colorScheme.secondary,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              "Logout",
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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
