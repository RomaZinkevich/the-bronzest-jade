import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/services/game_state_manager.dart';
import 'package:guess_who/services/websocket_service.dart';
import 'package:guess_who/widgets/game_board.dart';
import 'package:guess_who/widgets/make_guess_dialogue.dart';
import 'package:guess_who/widgets/retro_button.dart';
import 'package:provider/provider.dart';

enum TurnPhase { asking, answering }

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

  TurnPhase _currentPhase = TurnPhase.asking;
  String? _currentQuestion;
  bool _waitingForAnswer = false;

  final List<Map<String, String>> _qaHistory = [];
  final ScrollController _scrollController = ScrollController();
  bool _isMessageLogExpanded = false;
  final TextEditingController _questionController = TextEditingController();

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

      if (message.contains("asked: ")) {
        final parts = message.split(" asked: ");
        final question = parts[1];

        setState(() {
          _currentQuestion = question;
          _currentPhase = TurnPhase.answering;
        });
      } else if (message.contains("answered:")) {
        final parts = message.split(" answered: ");
        final answerId = parts[0].replaceAll("guest-player-", "");
        final answer = parts[1];

        setState(() {
          if (_currentQuestion != null) {
            _qaHistory.add({
              "question": _currentQuestion!,
              "questionerId": _gameState.isMyTurn
                  ? "guest-${widget.playerId.substring(0, 6)}"
                  : answerId,
              "answer": answer,
              "answeredId": answerId,
            });
            _currentQuestion = null;
          }
          _currentPhase = TurnPhase.asking;
          _waitingForAnswer = false;
          _isMessageLogExpanded = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        try {
          final jsonData = json.decode(message);
          if (jsonData["gameEnded"] == true) {
            _handleGameover(jsonData);
          }
        } catch (e) {
          debugPrint("Could not parse as JSON: $e");
        }
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

  void _sendAnswer(String answer) {
    widget.wsService.sendAnswer(answer);
    setState(() {
      _gameState.switchTurn();
      _currentPhase = TurnPhase.asking;
    });
  }

  void _handleGameover(Map<String, dynamic> response) {
    final winnerId = response["winnerId"];
    final isWinner = winnerId == widget.playerId;

    showDialog(
      context: context,
      barrierDismissible: false,
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
    setState(() {
      _gameState.toggleFlipCard(characterId);
    });
  }

  void _sendQuestion() {
    final question = _questionController.text.trim();

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please enter a question",
            textAlign: TextAlign.center,
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    widget.wsService.sendQuestion(question);
    setState(() {
      _currentQuestion = question;
      _currentPhase = TurnPhase.answering;
      _waitingForAnswer = true;
      _questionController.clear();
    });
  }

  void _makeGuess() {
    if (_currentPhase != TurnPhase.asking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "You can only make a guess during the asking phase!",
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
        );
      },
    );

    try {
      widget.wsService.sendGuess(guessedCharacter.id);
    } catch (e) {
      debugPrint('Error finishing game: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _gameState.dispose();
    _scrollController.dispose();
    _questionController.dispose();
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
                title: Column(
                  children: [
                    Text(
                      gameState.isMyTurn ? "Your Turn" : "Opponent's Turn",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _waitingForAnswer
                          ? "Waiting for answer..."
                          : (_currentPhase == TurnPhase.asking
                                ? "Ask or Guess"
                                : "Answer question"),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_qaHistory.isNotEmpty)
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                    width: 2,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.message_rounded,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),

                                      const SizedBox(width: 8),
                                      Text(
                                        "Q&A History (${_qaHistory.length})",
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
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                    child: Icon(
                                      Icons.expand_circle_down_rounded,
                                      size: 25,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSize(
                            clipBehavior: Clip.none,
                            curve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 150),
                            child: _isMessageLogExpanded
                                ? Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _qaHistory.length,
                                      itemBuilder: (context, index) {
                                        final qa = _qaHistory[index];
                                        final isMyQuestion = qa["questionerId"]!
                                            .contains(
                                              widget.playerId.substring(0, 6),
                                            );

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.question_mark_rounded,
                                                    size: 16,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),

                                                  const SizedBox(width: 6),

                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text:
                                                                "${isMyQuestion ? "You" : "Opponent"}: ",
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                qa["question"],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 4),

                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 22,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "➥ ",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.secondary,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: RichText(
                                                        text: TextSpan(
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .secondary,
                                                          ),
                                                          children: [
                                                            TextSpan(
                                                              text:
                                                                  "${!isMyQuestion ? "You" : "Opponent"}: ",
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  qa["answer"],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                    child: _currentPhase == TurnPhase.asking
                        ? _buildAskingPhaseUI(gameState)
                        : _buildAnsweringPhaseUI(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAskingPhaseUI(GameStateManager gameState) {
    final canAct = gameState.isMyTurn && !_waitingForAnswer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canAct) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: "Ask a question...",
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(150),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: _sendQuestion,
                  icon: Icon(
                    Icons.send_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canAct)
              Expanded(
                child: RetroButton(
                  text: "Make Guess",
                  onPressed: _makeGuess,
                  fontSize: 16,

                  iconSize: 24,
                  iconAtEnd: false,
                  icon: Icons.lightbulb_rounded,

                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              )
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _waitingForAnswer
                        ? "Waiting for opponent's answer..."
                        : "Opponent's turn",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnsweringPhaseUI() {
    if (_currentQuestion != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.question_mark_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Opponent asks:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentQuestion!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RetroButton(
                  text: "Yes",
                  fontSize: 16,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                  icon: Icons.check_circle_rounded,
                  iconAtEnd: false,
                  onPressed: () => _sendAnswer("Yes"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RetroButton(
                  text: "No",
                  fontSize: 16,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                  icon: Icons.do_not_disturb_alt_outlined,
                  iconAtEnd: false,
                  onPressed: () => _sendAnswer("No"),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary,
          width: 2,
        ),
      ),
      child: Text(
        "Opponent is thinking...",
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
