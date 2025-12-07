import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:guess_who/constants/assets/audio_assets.dart";
import "package:guess_who/models/character.dart";
import "package:guess_who/models/room.dart";
import "package:guess_who/services/audio_manager.dart";
import "package:guess_who/services/game_state_manager.dart";
import "package:guess_who/services/websocket_service.dart";
import "package:guess_who/widgets/common/retro_button.dart";
import "package:guess_who/widgets/common/retro_icon_button.dart";
import "package:guess_who/widgets/game/answering_phase_ui.dart";
import "package:guess_who/widgets/game/asking_phase_ui.dart";
import "package:guess_who/widgets/game/game_board.dart";
import "package:guess_who/widgets/game/make_guess_dialogue.dart";
import "package:guess_who/widgets/game/qa_message_log.dart";
import "package:provider/provider.dart";

enum TurnPhase { asking, answering }

class OnlineGameScreen extends StatefulWidget {
  final Room room;
  final String playerId;
  final String playerName;
  final bool isHost;
  final Character selectedCharacter;
  final WebsocketService wsService;
  final bool isMyTurnInitially;

  const OnlineGameScreen({
    super.key,
    required this.room,
    required this.playerId,
    required this.playerName,
    required this.isHost,
    required this.selectedCharacter,
    required this.wsService,
    required this.isMyTurnInitially,
  });

  @override
  State<StatefulWidget> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late GameStateManager _gameState;
  bool _isCharacterNameRevealed = false;

  TurnPhase _currentPhase = TurnPhase.asking;
  String? _currentQuestion;
  String? _currentQuestionerName;
  bool _waitingForAnswer = false;

  String? _opponentPlayerName;

  final List<Map<String, String>> _qaHistory = [];
  final ScrollController _scrollController = ScrollController();
  bool _isMessageLogExpanded = false;
  final TextEditingController _questionController = TextEditingController();

  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<String>? _errorSubscription;

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
      playerId: widget.playerId,
      roomId: widget.room.id,
      roomCode: widget.room.roomCode,
      isHost: widget.isHost,
    );

    _gameState.selectMyCharacter(widget.selectedCharacter);
    _gameState.startOnlineGame();
    _gameState.setMyTurn(widget.isMyTurnInitially);
  }

  void _listenToWebSocket() {
    _messageSubscription = widget.wsService.messageStream.listen(
      (message) {
        try {
          final Map<String, dynamic> jsonData = json.decode(message);
          debugPrint("Successfully parsed JSON: ${jsonData.keys}");

          if (jsonData.containsKey("gameEnded")) {
            if (jsonData["gameEnded"] == true) {
              debugPrint("Game over detected");
              _handleGameover(jsonData);
            } else {
              _handleIncorrectGuess(jsonData);
            }
          } else if (jsonData.containsKey("message")) {
            debugPrint("Message DTO detected: ${jsonData["message"]}");
            _handleMessageDto(jsonData["message"]);
          }
        } catch (e) {
          debugPrint("Failed to parse as JSON: $e");
          debugPrint("Treating as plain text message");
          _handleMessageDto(message);
        }
      },
      onError: (error) {
        debugPrint("Message stream error: $error");
      },
    );

    _errorSubscription = widget.wsService.errorStream.listen(
      (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, textAlign: TextAlign.center),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      onError: (error) {
        debugPrint("Error stream error: $error");
      },
    );

    debugPrint("Websocket listeners set up successfully");
  }

  String _extractPlayerName(String message) {
    final colonIndex = message.indexOf(":");
    if (colonIndex != -1) {
      return message.substring(0, colonIndex).trim();
    }
    return "Unknown";
  }

  void _handleMessageDto(String messageText) {
    if (messageText.contains("joined")) {
      debugPrint("Player joined: $messageText");
    } else if (messageText.contains("ready") ||
        messageText.contains("not ready")) {
      debugPrint("Ready status changed: $messageText");
    } else if (messageText.contains(" asked: ")) {
      final parts = messageText.split(" asked: ");
      if (parts.length < 2) return;

      final questionerName = _extractPlayerName(parts[0]);
      final question = parts[1];

      final isMyQuestion = questionerName == widget.playerName;

      debugPrint(
        "questionerName: $questionerName, playerName: ${widget.playerName}",
      );

      if (!isMyQuestion && _opponentPlayerName == null) {
        _opponentPlayerName = questionerName;
      }

      if (!mounted) return;

      setState(() {
        _currentQuestion = question;
        _currentQuestionerName = questionerName;
        _currentPhase = TurnPhase.answering;
      });
    } else if (messageText.contains(" answered: ")) {
      final parts = messageText.split(" answered: ");
      if (parts.length < 2) return;

      final answererName = _extractPlayerName(parts[0]);
      final answer = parts[1];

      final isMyAnswer = answererName == widget.playerName;

      if (!isMyAnswer && _opponentPlayerName == null) {
        _opponentPlayerName = answererName;
      }

      if (!mounted) return;

      setState(() {
        if (_currentQuestion != null && _currentQuestionerName != null) {
          final isQuestionerMe = _currentQuestionerName == widget.playerName;

          _qaHistory.add({
            "question": _currentQuestion!,
            "questionerName": _currentQuestionerName!,
            "isMyQuestion": isQuestionerMe.toString(),
            "answer": answer,
            "answererName": answererName,
            "isMyAnswer": isMyAnswer.toString(),
          });

          _currentQuestion = null;
          _currentQuestionerName = null;
        }

        _gameState.switchTurn();
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
    }
  }

  void _sendAnswer(String answer) {
    debugPrint("Sending answer: $answer");
    widget.wsService.sendAnswer(answer);

    if (!mounted) return;

    setState(() {
      _currentPhase = TurnPhase.asking;
    });
  }

  void _handleGameover(Map<String, dynamic> response) {
    final String winnerId = response["winnerId"];
    final isWinner = winnerId == widget.playerId;

    if (isWinner) {
      AudioManager().playGameWon();
    } else {
      AudioManager().playGameLost();
    }

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
                ? response["message"]
                : "Winner is Guest#${winnerId.substring(0, 6)}",
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

    debugPrint("Sending question: $question");
    widget.wsService.sendQuestion(question);
    AudioManager().playButtonClickVariation();
    setState(() {
      _currentQuestion = question;
      _currentPhase = TurnPhase.answering;
      _waitingForAnswer = true;
      _questionController.clear();
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
    try {
      widget.wsService.sendGuess(guessedCharacter.id);
    } catch (e) {
      debugPrint("Error finishing game: $e");
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send guess: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleIncorrectGuess(Map<String, dynamic> response) {
    AudioManager().wrongAnswerSfx();
    setState(() {
      _gameState.switchTurn();
      _currentPhase = TurnPhase.asking;
      _waitingForAnswer = false;
    });

    if (!mounted) return;

    final textStyle = _gameState.isMyTurn
        ? Text(
            "Opponent guessed ${response["guessedCharacterName"]} and was wrong",
            textAlign: TextAlign.center,
          )
        : Text(response["message"], textAlign: TextAlign.center);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: textStyle,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();
    _gameState.dispose();
    _scrollController.dispose();
    _questionController.dispose();
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
          "Leave Game?",
          style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
        ),
        content: Text(
          "Are you sure you want to leave this game?",
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
      widget.wsService.disconnect();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) async {
        if (didPop) return;

        _handleManualBack();
      },
      child: ChangeNotifierProvider.value(
        value: _gameState,
        child: Consumer<GameStateManager>(
          builder: (context, gameState, child) {
            return Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.tertiary,
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

                        tooltip: "Leave game",
                      )
                    : null,
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
                          : (gameState.isMyTurn
                                ? "Ask or Guess"
                                : "Answer question"),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: GameBoard(
                      gameState: gameState,
                      isCharacterNameRevealed: _isCharacterNameRevealed,
                      onToggleCharacterNameReveal: () {
                        AudioManager().playPopupSfx();
                        setState(() {
                          _isCharacterNameRevealed = !_isCharacterNameRevealed;
                        });
                      },
                      onFlip: (character) => _toggleFlipCard(character.id),
                      isSelectionMode: false,
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QAMessageLog(
                    qaHistory: _qaHistory,
                    isExpanded: _isMessageLogExpanded,
                    onToggleExpanded: () => {
                      setState(() {
                        _isMessageLogExpanded = !_isMessageLogExpanded;
                      }),
                    },
                    scrollController: _scrollController,
                    currentPlayerId: widget.playerId,
                    myPlayerName: widget.playerName,
                    opponentPlayerName: _opponentPlayerName,
                  ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: EdgeInsets.only(
                      top: 15,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).viewInsets.bottom + 15
                          : 45,
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
                        ? AskingPhaseUI(
                            gameState: gameState,
                            isWaitingForAnswer: _waitingForAnswer,
                            questionController: _questionController,
                            onSendQuestion: _sendQuestion,
                            onMakeGuess: _makeGuess,
                          )
                        : AnsweringPhaseUI(
                            isMyTurn: gameState.isMyTurn,
                            currentQuestion: _currentQuestion,
                            onSendAnswer: _sendAnswer,
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
