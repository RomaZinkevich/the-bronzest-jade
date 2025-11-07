import 'package:flutter/material.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/websocket_service.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/screens/online_game_screen.dart';
import 'package:guess_who/widgets/retro_button.dart';

class OnlineLobbyScreen extends StatefulWidget {
  final Room room;
  final String playerId;
  final bool isHost;

  const OnlineLobbyScreen({
    super.key,
    required this.room,
    required this.playerId,
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
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  bool _isMessageLogExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _wsService = WebsocketService();

    _wsService.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
    });

    _wsService.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });

      if (message.contains('started')) {
        _navigateToGame();
      }
    });

    _wsService.errorStream.listen((error) {
      setState(() {
        _errorMessage = error;
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select character: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _toggleReady() async {
    _isMessageLogExpanded = true;
    if (_selectedCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'Please select a character first',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      // await ApiService.toggleReady(widget.room.id, widget.playerId);
      _wsService.sendReady();

      setState(() {
        _isReady = !_isReady;
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start game: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineGameScreen(
          room: widget.room,
          playerId: widget.playerId,
          isHost: widget.isHost,
          selectedCharacter: _selectedCharacter!,
          wsService: _wsService,
        ),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    try {
      _wsService.disconnect();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to leave room: $e',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.room.characterSet?.characters ?? [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) async {
        if (didPop) return;

        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "Leave Room?",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            content: Text(
              "Are you sure you want to leave this room?",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Text(
                  "Leave",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldLeave == true && mounted) {
          await _leaveRoom();
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.tertiary,
          ),
          title: Text(
            'Room: ${widget.room.roomCode}',
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ),
        body: Column(
          children: [
            // Status bar
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

            // Characters grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
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

                  return GestureDetector(
                    onTap: () => _selectCharacter(character),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.secondary,
                          width: isSelected ? 4 : 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  character.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary.withAlpha(100),
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            child: Text(
                              character.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Message log
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
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ConstrainedBox(
                        constraints: _isMessageLogExpanded
                            ? const BoxConstraints(maxHeight: 150)
                            : const BoxConstraints(maxHeight: 0),
                        child: ClipRect(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  _messages[_messages.length - 1 - index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: (index % 2 == 0)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                                ),
                                child: Text(
                                  index == 0 ? "-> $message" : message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (index == 0)
                                        ? Theme.of(context).colorScheme.tertiary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.tertiary.withAlpha(150),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
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
                      onPressed: _startGame,
                      backgroundColor: Colors.green,
                      foregroundColor: Theme.of(context).colorScheme.tertiary,
                      icon: Icons.play_arrow,
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
