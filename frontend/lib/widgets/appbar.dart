import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String playerName;
  final String playerId;
  final String profilePicture;
  final VoidCallback onSettingsPressed;

  const CustomAppBar({
    super.key,
    this.profilePicture = "assets/bg.jpg",
    required this.playerName,
    required this.playerId,
    required this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: true,
      toolbarHeight: 80,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onSettingsPressed,
            icon: Icon(
              Icons.settings_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.secondary,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(2, 2),
                  blurRadius: 4,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
              CircleAvatar(radius: 25),
            ],
          ),
        ],
      ),
    );
  }
}
