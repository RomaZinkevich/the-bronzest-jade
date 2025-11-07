import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/services/game_state_manager.dart';
import 'package:guess_who/services/websocket_service.dart';

class OnlineGameScreen extends StatefulWidget {
  final Room room;
  final String playerId;
  final bool isHost;
  final Character selectedCharacter;
  final WebsocketService wsService;

  const OnlineGameScreen({
    super.key,
    required this.room,
    required this.playerId,
    required this.isHost,
    required this.selectedCharacter,
    required this.wsService,
  });

  @override
  State<StatefulWidget> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late GameStateManager _gameState;
  bool _isCharacterNameRevealed = false;

  @override
  void initState() {
    super.initState();

    _initializeGame();
    _listenToWebSocket();
  }

  void _initializeGame() {
    _gameState = GameStateManager();
    _gameState.initializeGame(
      mode: GameMode.online,
      characters: widget.room.characterSet!.characters,
      playerId: widget.room.id,
      roomId: widget.room.id,
      roomCode: widget.room.roomCode,
      isHost: widget.isHost,
    );

    _gameState.selectMyCharacter(widget.selectedCharacter);
    _gameState.startOnlineGame();
  }

  void _listenToWebSocket() {
    widget.wsService.messageStream.listen((message) {
      debugPrint("Game message: $message");

      if (message.contains("turn")) {
        _gameState.switchTurn();
      }
    });

    widget.wsService.errorStream.listen((error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }

  void _toggleFlipCard(String characterId) {
    if (!_gameState.isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("It's not your turn!"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    setState(() {
      _gameState.toggleFlipCard(characterId);
    });
  }

  void _makeGuess() {
    if (!_gameState.isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("It's not your turn!"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    final availableCharactes = _gameState.getAvailableCharacters();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          title: Text("Make Your Guess"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
