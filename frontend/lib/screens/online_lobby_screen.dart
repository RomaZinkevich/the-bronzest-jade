import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guess_who/constants/assets/audio_assets.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/audio_manager.dart';
import 'package:guess_who/services/websocket_service.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/screens/online_game_screen.dart';
import 'package:guess_who/widgets/character/character_card.dart';
import 'package:guess_who/widgets/common/retro_button.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';
import 'package:share_plus/share_plus.dart';

class OnlineLobbyScreen extends StatefulWidget {
  final Room room;
  final String playerId;
  final String playerName;
  final bool isHost;

  const OnlineLobbyScreen({
    super.key,
    required this.room,
    required this.playerId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  late WebsocketService _wsService;
  Character? _selectedCharacter;
  bool _isReady = false;
  bool _isConnected = false;
  final List<String> _messages = [];

  final ScrollController _scrollController = ScrollController();
  bool _isMessageLogExpanded = false;

  StreamSubscription<String>? _messageSubsciption;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    AudioManager().playBackgroundMusic(AudioAssets.lobbyMusic);
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _wsService = WebsocketService();

    _connectionSubscription = _wsService.connectionStream.listen((connected) {
      if (!mounted) return;

      setState(() {
        _isConnected = connected;
      });

      if (connected) {
        debugPrint("[Lobby] WebSocket connected");
      } else {
        debugPrint("[Lobby] WebSocket disconnected");
      }
    });

    _messageSubsciption = _wsService.messageStream.listen((message) {
      if (!mounted) return;

      setState(() {
        _messages.add(message);
      });

      try {
        final Map<String, dynamic> jsonData = json.decode(message);

        if (jsonData.containsKey("turnPlayer")) {
          debugPrint("[Lobby] Game starting, navigating to game screen");
          _navigateToGame(jsonData);
        } else if (jsonData.containsKey("message")) {
          final messageText = jsonData["message"];
          if (messageText.contains("joined") && _messages.length > 1) {
            setState(() {
              _isMessageLogExpanded = true;
            });
          }
        }
      } catch (e) {
        if (message.contains("started")) {
          _navigateToGame(null);
        }

        if (message.contains("joined") && _messages.length > 1) {
          setState(() {
            _isMessageLogExpanded = true;
          });
        }
      }
    });

    _errorSubscription = _wsService.errorStream.listen((error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });

    _wsService.connect(widget.room.id, widget.playerId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _selectCharacter(Character character) async {
    try {
      AudioManager().playPopupSfx();
      await ApiService.selectCharacter(
        widget.room.id,
        widget.playerId,
        character.id,
      );

      setState(() {
        _selectedCharacter = character;
      });

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select character: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _toggleReady() async {
    if (_selectedCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            "Please select a character first",
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      _wsService.sendReady();

      setState(() {
        _isReady = !_isReady;
        _isMessageLogExpanded = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle ready: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _startGame() async {
    if (!widget.isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Only the host can start the game',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      _wsService.sendStart();
      AudioManager().playAlertSfx();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start game: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToGame(Map<String, dynamic>? startGameResponse) {
    _messageSubsciption?.cancel();
    _errorSubscription?.cancel();
    _connectionSubscription?.cancel();

    bool isMyTurnInitially = false;

    if (startGameResponse != null &&
        startGameResponse.containsKey("turnPlayer")) {
      final turnPlayerData = startGameResponse["turnPlayer"];
      final turnPlayerId = turnPlayerData["userId"];
      isMyTurnInitially = turnPlayerId == widget.playerId;
    }

    AudioManager().playGameStart();
    AudioManager().playBackgroundMusic(
      AudioAssets.gameMusic,
      fadeDuration: const Duration(seconds: 3),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineGameScreen(
          room: widget.room,
          playerId: widget.playerId,
          playerName: widget.playerName,
          isHost: widget.isHost,
          selectedCharacter: _selectedCharacter!,
          wsService: _wsService,
          isMyTurnInitially: isMyTurnInitially,
        ),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    _wsService.disconnect();
    try {
      await ApiService.leaveRoom(widget.room.id, widget.playerId);
    } catch (e) {
      debugPrint("[Lobby] Failed to leave room via API: $e");
    }
  }

  Future<void> _shareRoomCode() async {
    final roomCode = widget.room.roomCode;
    final deepLink = "https://guesswho.190304.xyz/join?code=$roomCode";

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: "Join my Guess Who game with room code $roomCode!\n\n$deepLink",
          subject: "Join Guess Who Game - $roomCode",
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to share: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageSubsciption?.cancel();
    _errorSubscription?.cancel();
    _connectionSubscription?.cancel();

    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleManualBack() async {
    if (!mounted) return;
    final ctx = context;

    final shouldLeave = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.tertiary,
        title: Text(
          "Leave Room?",
          style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
        ),
        content: Text(
          "Are you sure you want to leave this room?",
          style: TextStyle(color: Theme.of(ctx).colorScheme.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioManager().playButtonClick();
              Navigator.pop(ctx, false);
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
            ),
          ),
          // FilledButton(
          //   onPressed: ,
          //   style: ButtonStyle(
          //     backgroundColor: WidgetStatePropertyAll(
          //       Theme.of(ctx).colorScheme.error,
          //     ),
          //   ),
          //   child: Text(
          //     "Leave",
          //     style: TextStyle(color: Theme.of(ctx).colorScheme.tertiary),
          //   ),
          // ),
          RetroButton(
            text: "Leave",
            onPressed: () => Navigator.pop(ctx, true),
            backgroundColor: Theme.of(ctx).colorScheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      await _leaveRoom();
      if (ctx.mounted) {
        AudioManager().playBackgroundMusic(
          AudioAssets.menuMusic,
          fadeDuration: const Duration(seconds: 3),
        );
        Navigator.pop(ctx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.room.characterSet?.characters ?? [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) async {
        if (didPop) return;

        _handleManualBack();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.tertiary,
          ),
          title: Text(
            widget.room.roomCode,
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 16,
            ),
          ),
          leading: Navigator.canPop(context)
              ? RetroIconButton(
                  icon: Icons.arrow_back_rounded,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  iconSize: 26,

                  margin: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 0,
                  ),
                  borderWidth: 2,
                  onPressed: _handleManualBack,

                  tooltip: "Go back home",
                )
              : null,
          actions: !widget.isHost
              ? null
              : [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: RetroButton(
                      text: "Share Code",
                      fontSize: 14,
                      iconSize: 20,
                      iconAtEnd: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.tertiary,
                      icon: Icons.share_rounded,
                      onPressed: _shareRoomCode,
                      borderWidth: 2,
                    ),
                  ),
                ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isConnected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnected
                            ? 'Connected ${widget.isHost ? "as the host" : "as a guest"}'
                            : 'Connecting...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.tertiary,
                child: GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected = _selectedCharacter?.id == character.id;

                    return CharacterCard(
                      character: character,
                      isFlipped: isSelected,
                      isSelectionMode: true,
                      onSelect: () => _selectCharacter(character),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            if (_messages.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isMessageLogExpanded = !_isMessageLogExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.tertiary,
                              width: 2,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.message_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Messages (${_messages.length})",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedRotation(
                              turns: _isMessageLogExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Icon(
                                Icons.expand_circle_down_rounded,
                                size: 25,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    AnimatedSize(
                      clipBehavior: Clip.none,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      child: _isMessageLogExpanded
                          ? Container(
                              constraints: const BoxConstraints(maxHeight: 150),
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final rawMessage =
                                      _messages[_messages.length - 1 - index];

                                  String displayMessage = rawMessage;

                                  try {
                                    final Map<String, dynamic> jsonData = json
                                        .decode(rawMessage);
                                    if (jsonData.containsKey("message")) {
                                      displayMessage = jsonData["message"];
                                    }
                                  } catch (e) {
                                    displayMessage = rawMessage;
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (index % 2 == 0)
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                    ),
                                    child: Text(
                                      index == 0
                                          ? "-> $displayMessage"
                                          : displayMessage,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (index == 0)
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.tertiary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                                  .withAlpha(150),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.only(
                top: 15,
                bottom: 45,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                border: _isMessageLogExpanded
                    ? Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 4,
                        ),
                      )
                    : null,
                boxShadow: _isMessageLogExpanded
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RetroButton(
                    text: _isReady ? "Not Ready" : "Ready",
                    onPressed: _toggleReady,
                    fontSize: 16,
                    iconSize: 24,
                    iconSpacing: 8,
                    iconAtEnd: false,
                    padding: const EdgeInsets.all(12),
                    backgroundColor: _isReady
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.tertiary,
                    icon: _isReady ? Icons.close : Icons.check,
                  ),
                  const SizedBox(width: 10),
                  if (widget.isHost)
                    RetroButton(
                      text: "Start Game",
                      fontSize: 16,
                      iconSize: 24,
                      iconSpacing: 6,
                      iconAtEnd: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onPressed: () {
                        _startGame();
                      },

                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.tertiary,
                      icon: Icons.play_arrow_rounded,
                      playOnClick: false,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
