import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_who/screens/gamescreen.dart';
import 'package:guess_who/widgets/appbar.dart';
import 'package:guess_who/widgets/popup_menu.dart';
import 'package:guess_who/widgets/retro_button.dart';
import 'package:guess_who/widgets/retro_icon_button.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

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
                SystemNavigator.pop();
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

  void _joinWithCode() {
    String code = _roomCodeController.text.trim();
    if (code.isNotEmpty) {
      debugPrint("Joining room with code: $code");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please enter a room code",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showCreateRoomMenu() {
    PopupMenu.show(
      context: context,
      title: "Create a Room",
      items: [
        RetroPopupMenuItem(
          text: "Public Room",
          icon: Icons.public,
          onTap: () {
            debugPrint("Creating public room");
          },
        ),

        RetroPopupMenuItem(
          text: "Private Room",
          icon: Icons.lock,
          onTap: () {
            debugPrint("Creating friends only room");
          },
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  void _showFindRoomsMenu() {
    PopupMenu.show(
      context: context,
      title: "Find Rooms",
      items: [
        RetroPopupMenuItem(
          text: "Browse Public",
          icon: Icons.search,
          onTap: () {
            debugPrint("Browsing public rooms");
            _showRoomList();
          },
        ),

        RetroPopupMenuItem(
          text: "Friends' Rooms",
          icon: Icons.people,
          onTap: () {
            debugPrint("Finding Friends Room");
          },
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRooms() async {
    final randomNum = Random.secure().nextInt(5);
    await Future.delayed(Duration(seconds: randomNum));

    return [
      {
        'name': 'Epic Showdown',
        'code': 'ABC123',
        'players': 2,
        'maxPlayers': 4,
        'isPrivate': false,
      },
      {
        'name': 'Friends Game',
        'code': 'XYZ789',
        'players': 3,
        'maxPlayers': 4,
        'isPrivate': true,
      },
      {
        'name': 'Quick Match',
        'code': 'QWE456',
        'players': 1,
        'maxPlayers': 2,
        'isPrivate': false,
      },
      {
        'name': 'Tournament Finals',
        'code': 'ZXC999',
        'players': 4,
        'maxPlayers': 4,
        'isPrivate': false,
      },
      {
        'name': 'Chill Game',
        'code': 'ASD111',
        'players': 1,
        'maxPlayers': 3,
        'isPrivate': false,
      },
    ];
  }

  void _showRoomList() {
    PopupMenu.show<List<Map<String, dynamic>>>(
      context: context,
      title: "Available Rooms",
      customContent: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    strokeWidth: 4,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Fetching available rooms...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Failed to load rooms",
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Please try again later",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "No rooms available",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Create a room to get started!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data!;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: rooms
                .map(
                  (room) => RoomListItem(
                    roomName: room["name"] as String,
                    roomCode: room["code"] as String,
                    playerCount: room["players"] as int,
                    maxPlayers: room["maxPlayers"] as int,
                    isPrivate: room["isPrivate"] as bool,
                    onJoin: () {
                      debugPrint("Joining room: ${room["code"]}");
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
      maxHeight: MediaQuery.of(context).size.height * 0.7,
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

          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 90,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Image(
                      image: AssetImage("assets/main_logo.png"),
                      width: 300,
                    ),

                    const SizedBox(height: 100),

                    RetroButton(
                      text: "Play local",
                      fontSize: 18,

                      icon: Icons.videogame_asset,
                      iconSize: 30,
                      iconAtEnd: true,

                      padding: EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 15,
                      ),

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

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 30),
                      padding: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        border: BoxBorder.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(100),
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  const BoxShadow(color: Color(0xFF5B7B76)),
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    blurRadius: 4,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _roomCodeController,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Join with code...",
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary.withAlpha(150),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 4),

                          RetroIconButton(
                            onPressed: _joinWithCode,
                            tooltip: "Join with code",
                            imagePath: "assets/icons/join_submit.png",
                            iconSize: 65,
                            padding: 0,
                            margin: EdgeInsets.only(right: 5),

                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RetroButton(
                          text: 'Create a room',
                          fontSize: 18,

                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),

                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          onPressed: _showCreateRoomMenu,
                        ),

                        SizedBox(width: 8),

                        RetroIconButton(
                          onPressed: _showFindRoomsMenu,
                          tooltip: "Find rooms",
                          imagePath: "assets/icons/find_room.png",
                          iconSize: 55,
                          padding: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
