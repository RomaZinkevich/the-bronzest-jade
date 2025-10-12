import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String playerName;
  final String playerId;
  final String profilePicture;
  final VoidCallback onSettingsPressed;

  const CustomAppBar({
    super.key,
    this.profilePicture = "assets/icons/default_user.png",
    required this.playerName,
    required this.playerId,
    required this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90);

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
        children: [
          IconButton(
            onPressed: onSettingsPressed,
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
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
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
                  ),
                  Text(
                    playerId,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color.fromARGB(125, 0, 0, 0),
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
                  child: CircleAvatar(
                    radius: 25,
                    foregroundImage: AssetImage(profilePicture),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
