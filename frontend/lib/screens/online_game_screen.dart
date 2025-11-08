import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/services/game_state_manager.dart';
import 'package:guess_who/services/websocket_service.dart';
import 'package:guess_who/widgets/game_board.dart';
import 'package:guess_who/widgets/make_guess_dialogue.dart';
import 'package:guess_who/widgets/retro_button.dart';
import 'package:provider/provider.dart';

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
        setState(() {
          _gameState.switchTurn();
        });
      } else if (message.contains("winner")) {
        _handleGameover(message);
      } else if (message.contains("started")) {
        debugPrint("Game started message recieved!");
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

  void _handleGameover(String message) {
    setState(() {
      _gameState.resetGame();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isWinner = message.contains(widget.playerId);

        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
          title: Column(
            children: [
              Icon(
                isWinner ? Icons.emoji_events : Icons.cancel,
                size: 60,
                color: isWinner
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(
                isWinner ? "You Won!" : "You Lost!",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            isWinner
                ? "Congratulations! You guessed correctly!"
                : "Better luck next time!",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                "Exit to Menu",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleFlipCard(String characterId) {
    if (!_gameState.isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "It's not your turn!",
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 1),
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
          content: const Text(
            "It's not your turn!",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    final availableCharacters = _gameState.getAvailableCharacters();

    makeGuessDialogue(
      context,
      availableCharacters: availableCharacters,
      onGuessSelected: _checkGuess,
    );
  }

  Future<void> _checkGuess(Character guessedCharacter) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
          title: Text(
            "Guess Submitted",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "You guessed: ${guessedCharacter.name}\n\nWait for the result from the server...",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Finish game through API
    try {
      widget.wsService.sendGuess(guessedCharacter.id);
    } catch (e) {
      debugPrint('Error finishing game: $e');
    }
  }

  void _endTurn() {
    if (!_gameState.isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "It's not your turn!",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    widget.wsService.sendQuestion("Is your mom gay?");

    setState(() {
      _isCharacterNameRevealed = false;
    });
  }

  void _endTurn2() {
    if (_gameState.isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "It's not your turn!",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    widget.wsService.sendAnswer("Yes");

    setState(() {
      _isCharacterNameRevealed = false;
    });
  }

  @override
  void dispose() {
    widget.wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

        if (shouldLeave == true) {
          widget.wsService.disconnect();

          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: ChangeNotifierProvider.value(
        value: _gameState,
        child: Consumer<GameStateManager>(
          builder: (context, gameState, child) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                title: Text(
                  gameState.isMyTurn ? "Your Turn" : "Opponent's Turn",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 20,
                  ),
                ),
              ),
              body: GameBoard(
                gameState: gameState,
                isCharacterNameRevealed: _isCharacterNameRevealed,
                onToggleCharacterNameReveal: () {
                  setState(() {
                    _isCharacterNameRevealed = !_isCharacterNameRevealed;
                  });
                },
                onFlip: (character) => _toggleFlipCard(character.id),
                isSelectionMode: false,
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.only(top: 15, bottom: 45),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RetroButton(
                          text: "Make Guess",
                          onPressed: gameState.isMyTurn ? _makeGuess : () {},
                          fontSize: 16,
                          iconSize: 30,
                          iconAtEnd: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          backgroundColor: gameState.isMyTurn
                              ? Theme.of(context).colorScheme.error
                              : Colors.grey,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                          icon: Icons.lightbulb_rounded,
                        ),
                        const SizedBox(width: 10),
                        RetroButton(
                          text: "Ask",
                          fontSize: 16,
                          iconSize: 30,
                          iconAtEnd: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          onPressed: gameState.isMyTurn ? _endTurn : () {},
                          backgroundColor: gameState.isMyTurn
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                          icon: Icons.swap_horiz_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    RetroButton(
                      text: "Answer",
                      fontSize: 16,
                      iconSize: 30,
                      iconAtEnd: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      onPressed: !gameState.isMyTurn ? _endTurn2 : () {},
                      backgroundColor: !gameState.isMyTurn
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.grey,
                      foregroundColor: Theme.of(context).colorScheme.tertiary,
                      icon: Icons.swap_horiz_rounded,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
