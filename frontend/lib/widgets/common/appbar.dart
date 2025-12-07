import 'package:flutter/material.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';
import 'package:guess_who/widgets/settings_dropdown.dart';
import 'package:guess_who/widgets/common/popup_menu.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String playerName;
  final String playerId;
  final String profilePicture;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onCreateCharacterSetPressed;
  final VoidCallback? onSignUpPressed;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onLogoutPressed;
  final bool isAuthenticated;

  const CustomAppBar({
    super.key,
    this.profilePicture = "assets/icons/default_user.png",
    required this.playerName,
    required this.playerId,
    required this.onSettingsPressed,
    this.onCreateCharacterSetPressed,
    this.onSignUpPressed,
    this.onLoginPressed,
    this.onLogoutPressed,
    this.isAuthenticated = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90);

  void _showAccountMenu(BuildContext context) {
    final List<RetroPopupMenuItem> menuItems = [];

    if (!isAuthenticated) {
      menuItems.addAll([
        RetroPopupMenuItem(
          text: "Sign Up",
          icon: Icons.person_add_rounded,
          onTap: () => onSignUpPressed?.call(),
        ),
        RetroPopupMenuItem(
          text: "Log In",
          icon: Icons.login_rounded,
          onTap: () => onLoginPressed?.call(),
        ),
      ]);
    } else {
      menuItems.add(
        RetroPopupMenuItem(
          text: "Logout",
          icon: Icons.logout_rounded,
          onTap: () => onLogoutPressed?.call(),
        ),
      );
    }

    PopupMenu.show(context: context, title: "Account", items: menuItems);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      automaticallyImplyLeading: true,
      toolbarHeight: 90,
      elevation: 4,
      shadowColor: Colors.black,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const SettingsDropdown(),

              // RetroIconButton(
              //   onPressed: () {},
              //   icon: Icons.settings_rounded,
              //   iconSize: 30,
              //   padding: 10,

              //   tooltip: "Settings",

              //   backgroundColor: Theme.of(context).colorScheme.tertiary,
              //   iconColor: Theme.of(context).colorScheme.secondary,
              // ),
              RetroIconButton(
                onPressed: () {
                  onCreateCharacterSetPressed?.call();
                },
                icon: Icons.library_add_rounded,
                iconSize: 30,
                padding: 10,

                tooltip: "Add character set",

                backgroundColor: Theme.of(context).colorScheme.tertiary,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),

          GestureDetector(
            onTap: () {
              _showAccountMenu(context);
            },
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 150),
                      child: Text(
                        playerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.tertiary,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Text(
                      playerId,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    child: Icon(
                      Icons.person_rounded,
                      size: 35,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
