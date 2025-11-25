import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_who/screens/create_characterset_screen.dart';
import 'package:guess_who/screens/local_game_screen.dart';
import 'package:guess_who/screens/online_lobby_screen.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/widgets/appbar.dart';
import 'package:guess_who/widgets/inner_shadow_input.dart';
import 'package:guess_who/widgets/popup_menu.dart';
import 'package:guess_who/widgets/retro_button.dart';
import 'package:guess_who/widgets/retro_icon_button.dart';
import 'package:uuid/uuid.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  final String _playerId = const Uuid().v4();

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

  Future<void> _joinWithCode() async {
    String code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please enter a room code",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    //* LOADING
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          strokeCap: StrokeCap.round,
          strokeWidth: 5,
        ),
      ),
    );

    try {
      final room = await ApiService.joinRoom(code, _playerId);

      if (mounted) {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineLobbyScreen(
              room: room,
              playerId: _playerId,
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("$e");
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to join room: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showCreateRoomMenu() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          strokeWidth: 5,
          strokeCap: StrokeCap.round,
        ),
      ),
    );

    try {
      final characterSets = await ApiService.getCharacterSets();

      if (mounted) {
        Navigator.pop(context);

        if (characterSets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("No character sets available"),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }

        PopupMenu.show(
          context: context,
          title: "Select Character Set",
          items: characterSets
              .map(
                (characterSets) => RetroPopupMenuItem(
                  text: characterSets.name,
                  onTap: () => _createRoom(characterSets.id),
                ),
              )
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        debugPrint("$e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to load character sets"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createRoom(String characterSetId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          strokeWidth: 5,
          strokeCap: StrokeCap.round,
        ),
      ),
    );

    try {
      final room = await ApiService.createRoom(_playerId, characterSetId);

      if (mounted) {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineLobbyScreen(
              room: room,
              playerId: _playerId,
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        debugPrint("$e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to create room"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
            debugPrint("Browsing public rooms - Sample set");
            _showSampleRoomList();
          },
        ),

        RetroPopupMenuItem(
          text: "Friends' Rooms",
          icon: Icons.people,
          onTap: () {
            debugPrint("Finding Friends Room");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Friends' room feature coming soon!",
                  textAlign: TextAlign.center,
                ),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchSampleRooms() async {
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

  void _showSampleRoomList() {
    PopupMenu.show<List<Map<String, dynamic>>>(
      context: context,
      title: "Available Rooms",
      customContent: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSampleRooms(),
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
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
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
        playerName: "Guest Player",
        playerId: "#${_playerId.substring(0, 6)}",
        onSettingsPressed: () {},
        onCreateCharacterSetPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateCharactersetScreen(playerId: _playerId),
            ),
          );
        },
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
                      fontSize: 20,

                      icon: Icons.videogame_asset,
                      iconSize: 34,
                      iconAtEnd: true,

                      padding: EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),

                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocalGameScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    InnerShadowInput(
                      controller: _roomCodeController,
                      onSubmit: _joinWithCode,
                      submitTooltip: "Join with code",
                      hintText: "Join with code...",
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RetroButton(
                          text: 'Create a room',
                          fontSize: 18,

                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),

                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          onPressed: _showCreateRoomMenu,
                        ),

                        SizedBox(width: 4),

                        RetroIconButton(
                          onPressed: _showFindRoomsMenu,
                          tooltip: "Find rooms",
                          imagePath: "assets/icons/find_room.png",
                          iconSize: 55,
                          padding: 6,
                          borderWidth: 0,
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
