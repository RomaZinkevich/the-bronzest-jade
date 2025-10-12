import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_who/gamescreen.dart';
import 'package:guess_who/widgets/appbar.dart';
import 'package:guess_who/widgets/retro_button.dart';
import 'package:guess_who/widgets/retro_icon_button.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void confirmQuit(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Quit app"),
          content: const Text("Are you sure you want to quit the app?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                () {
                  debugPrint("hello");
                  SystemNavigator.pop();
                };
              },
              child: Text(
                "Quit",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        playerName: "GUEST PLAYER",
        playerId: "#123456",
        onSettingsPressed: () {},
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image(
              image: AssetImage("assets/main_menu.png"),
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Image(
                  image: AssetImage("assets/main_logo.png"),
                  width: 300,
                ),

                const SizedBox(height: 100),

                RetroButton(
                  text: "PLAY LOCAL",
                  fontSize: 18,

                  icon: Icons.videogame_asset,
                  iconSize: 40,
                  iconAtEnd: true,

                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RetroButton(
                      text: 'CREATE A ROOM',
                      fontSize: 18,

                      backgroundColor: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        // Navigate to create room
                      },
                    ),

                    SizedBox(width: 8),

                    RetroIconButton(
                      onPressed: () {},
                      imagePath: "assets/icons/find_room.png",
                      iconSize: 50,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
