import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_who/constants/assets/audio_assets.dart';
import 'package:guess_who/screens/create_characterset_screen.dart';
import 'package:guess_who/screens/local_game_screen.dart';
import 'package:guess_who/screens/online_lobby_screen.dart';
import 'package:guess_who/widgets/auth_popup.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/audio_manager.dart';
import 'package:guess_who/services/auth_service.dart';
import 'package:guess_who/services/deep_link_service.dart';
import 'package:guess_who/widgets/common/appbar.dart';
import 'package:guess_who/widgets/common/inner_shadow_input.dart';
import 'package:guess_who/widgets/common/popup_menu.dart';
import 'package:guess_who/widgets/common/retro_button.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';
import 'package:guess_who/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final TextEditingController _roomCodeController = TextEditingController();

  String _playerId = "";
  String _playerName = "";
  bool _isAuthenticated = false;

  bool _isJoining = false;
  bool _dialogOpen = false;
  bool _screenActive = true;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    });

    DeepLinkService().addListener(_checkPendingDeepLink);
  }

  Future<void> _initializeAudio() async {
    await AudioManager().setMusicVolume(0.3);

    await AudioManager().playBackgroundMusic(
      AudioAssets.menuMusic,
      fadeDuration: const Duration(seconds: 6),
    );
  }

  Future<void> _initialize() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = await AuthService.getUserId();
    final username = await AuthService.getUsername();
    final isAuth = await AuthService.isAuthenticated();

    setState(() {
      _playerId = userId ?? "";
      _playerName = username ?? "Guest";
      _isAuthenticated = isAuth;
    });

    _checkPendingDeepLink();
  }

  void _checkPendingDeepLink() {
    final deepLinkService = DeepLinkService();
    final roomCode = deepLinkService.pendingRoomCode;

    if (roomCode == null || roomCode.isEmpty) return;

    deepLinkService.clearPendingRoomCode();
    _roomCodeController.text = roomCode;

    if (_playerId.isEmpty) return;

    if (mounted) {
      _joinWithCode();
    }
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _screenActive = false;
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
    if (!_screenActive) return;
    if (_isJoining) return;
    _isJoining = true;

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

      _isJoining = false;
      return;
    }

    if (mounted) {
      _dialogOpen = true;

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
      ).then((_) {
        _dialogOpen = false;
      });
    }

    try {
      final room = await ApiService.joinRoom(code, _playerId);

      if (!mounted) return;

      if (_dialogOpen && _screenActive) {
        Navigator.of(context, rootNavigator: true).pop();
        _dialogOpen = false;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineLobbyScreen(
            room: room,
            playerId: _playerId,
            playerName: _playerName,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint("$e");
      if (mounted && _dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop(context);
        _dialogOpen = true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to join room: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      _isJoining = false;
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
                (characterSet) => RetroPopupMenuItem(
                  text: characterSet.name,
                  onTap: () {
                    _createRoom(characterSet.id);
                  },
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

  Future<void> _showSignUpDialog() async {
    final result = await AuthPopup.showSignUp(context);
    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _showLoginDialog() async {
    final result = await AuthPopup.showLogin(context);
    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _logout() async {
    AudioManager().playAlertSfx();
    await AuthService.clearAuthData();

    // Create new guest user
    try {
      final guestResponse = await ApiService.createGuestUser();
      await AuthService.saveAuthData(
        token: guestResponse["token"],
        userId: guestResponse["userId"],
        username: guestResponse["username"],
        isGuest: true,
      );
    } catch (e) {
      debugPrint("Failed to create guest user: $e");
    }

    await _loadUserData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Logged out successfully"),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
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
              playerName: _playerName,
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: CustomAppBar(
            playerName: _playerName,
            playerId:
                "#${_playerId.isNotEmpty ? _playerId.substring(0, 6) : ""}",
            onSettingsPressed: () {},
            onSignUpPressed: _showSignUpDialog,
            onLoginPressed: _showLoginDialog,
            onLogoutPressed: _logout,
            isAuthenticated: _isAuthenticated,
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
                child: Image.asset(
                  "assets/main_menu.png",
                  fit: BoxFit.cover,
                  color: settings.isDarkMode ? Colors.black54 : null,
                  colorBlendMode: settings.isDarkMode ? BlendMode.darken : null,
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
                            AudioManager().playGameStart();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LocalGameScreen(),
                              ),
                            );
                          },

                          playOnClick: false,
                        ),

                        const SizedBox(height: 60),

                        InnerShadowInput(
                          controller: _roomCodeController,
                          onSubmit: () => _joinWithCode(),
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
                              onPressed: () {
                                _showCreateRoomMenu();
                              },
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
      },
    );
  }
}
