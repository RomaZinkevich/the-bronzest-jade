import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_who/constants/assets/audio_assets.dart';
import 'package:guess_who/data/game_data.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/services/audio_manager.dart';
import 'package:guess_who/services/game_state_manager.dart';
import 'package:guess_who/widgets/common/retro_button.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';
import 'package:guess_who/widgets/game/make_guess_dialogue.dart';
import 'package:particles_flutter/component/particle/particle.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:provider/provider.dart';

class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  late GameStateManager _gameState;
  GamePhase? _previousPhase;
  bool _isLoading = false;
  bool _isCharacterNameRevealed = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameStateManager();
    _gameState.addListener(_onGameStateChanged);
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final characters = await GameData.fetchCharacters();
      _gameState.initializeGame(mode: GameMode.local, characters: characters);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching characters: $e");
    }
  }

  void _selectCharacter(Character character) {
    setState(() {
      _gameState.selectMyCharacter(character);
    });
  }

  void _toggleFlipCard(String characterId) {
    setState(() {
      _gameState.toggleFlipCard(characterId);
    });
  }

  void _endTurn() {
    setState(() {
      _gameState.endLocalTurn();
      _isCharacterNameRevealed = false;
    });

    _showTurnTransitionOverlay();
  }

  void _showTurnTransitionOverlay() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.primary,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Stack(
            children: [
              Container(
                color: Theme.of(context).colorScheme.primary,
                child: Particles(
                  awayRadius: 150,
                  particles: _createParticles(),
                  height: screenHeight,
                  width: screenWidth,
                  onTapAnimation: true,
                  awayAnimationDuration: const Duration(milliseconds: 100),
                  awayAnimationCurve: Curves.bounceOut,
                  enableHover: true,
                  hoverRadius: 30,
                  connectDots: false,
                ),
              ),
              Dialog(
                backgroundColor: Colors.transparent,
                elevation: 10,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withAlpha(100),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              offset: Offset(0, 2),
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(100),
                            ),
                          ],
                        ),
                        child: Text(
                          _gameState.getCurrentPlayerName() == "Player 1"
                              ? "Player 2"
                              : "Player 1",
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),

                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 50,
                        color: Theme.of(context).colorScheme.secondary,
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 2,
                              offset: Offset(0, 2),
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(200),
                            ),
                          ],
                        ),
                        child: Text(
                          _gameState.getCurrentPlayerName(),
                          style: TextStyle(
                            fontSize: 22,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: RetroButton(
                          text: "I'm Ready!",
                          fontSize: 18,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,

                          borderColor: Theme.of(context).colorScheme.tertiary,
                          borderRadius: 12,

                          icon: Icons.check_circle,
                          iconAtEnd: false,
                          iconSize: 30,
                          iconSpacing: 10,

                          padding: EdgeInsets.symmetric(
                            vertical: 25,
                            horizontal: 0,
                          ),

                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Particle> _createParticles() {
    var rng = Random();
    List<Particle> particles = [];
    for (int i = 0; i < 50; i++) {
      particles.add(
        Particle(
          color: Theme.of(context).colorScheme.tertiary.withAlpha(200),
          size: rng.nextDouble() * 10,
          velocity: Offset(
            rng.nextDouble() * 50 * _randomSign(),
            rng.nextDouble() * 50 * _randomSign(),
          ),
        ),
      );
    }
    return particles;
  }

  double _randomSign() {
    var rng = Random();
    return rng.nextBool() ? 1 : -1;
  }

  //TODO: POLISH
  void _makeGuess() {
    final availableCharacters = _gameState.getAvailableCharacters();
    AudioManager().playButtonClickVariation();

    makeGuessDialogue(
      context,
      availableCharacters: availableCharacters,
      onGuessSelected: _checkGuess,
    );
  }

  void _checkGuess(Character guessedCharacter) {
    final isCorrect = _gameState.makeGuess(guessedCharacter);

    if (isCorrect) {
      _showWinnerDialog();
    } else {
      _showIncorrectGuessDialog();
    }
  }

  void _showWinnerDialog() {
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
                Icons.emoji_events,
                size: 60,
                color: Theme.of(context).colorScheme.secondary,
              ),

              const SizedBox(height: 10),

              Text(
                "Game Over",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            "${_gameState.winner} wins the game",
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
                _resetGame();
              },
              child: Text(
                "Play Again",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

  void _showIncorrectGuessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 4,
            ),
          ),
          title: Column(
            children: [
              Icon(
                Icons.cancel,
                size: 60,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(
                "Wrong Guess!",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            "${_gameState.getCurrentPlayerName()} guessed incorrectly and loses!",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showWinnerDialog();
              },
              child: Text(
                "OK",
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

  void _resetGame() {
    setState(() {
      _gameState.resetGame();
      _isCharacterNameRevealed = false;
      _initializeGame();
    });
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);

    AudioManager().playBackgroundMusic(
      AudioAssets.menuMusic,
      fadeDuration: const Duration(seconds: 6),
    );
    super.dispose();
  }

  void _onGameStateChanged() {
    if (_previousPhase != _gameState.gamePhase) {
      _previousPhase = _gameState.gamePhase;

      switch (_gameState.gamePhase) {
        case GamePhase.characterSelection:
          AudioManager().playBackgroundMusic(
            AudioAssets.lobbyMusic,
            fadeDuration: const Duration(seconds: 3),
          );
          break;

        case GamePhase.playing:
          AudioManager().playBackgroundMusic(
            AudioAssets.gameMusic,
            fadeDuration: const Duration(seconds: 3),
          );
          break;

        case GamePhase.gameOver:
          // Optionally play different music or stop music on game over
          // AudioManager().stopBackgroundMusic();
          break;

        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
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
                gameState.gamePhase == GamePhase.characterSelection
                    ? "Select Your Character"
                    : "${gameState.getCurrentPlayerName()}'s Turn",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontSize: 20,
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

                      onPressed: () {
                        Navigator.of(context).pop();
                      },

                      tooltip: "Go back home",
                    )
                  : null,
            ),
            body: _buildBody(gameState),
            bottomNavigationBar: gameState.gamePhase == GamePhase.playing
                ? Container(
                    padding: EdgeInsets.only(top: 15, bottom: 45),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RetroButton(
                          text: "Make Guess",
                          onPressed: _makeGuess,
                          fontSize: 16,
                          iconSize: 30,
                          iconAtEnd: false,

                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),

                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,

                          icon: Icons.lightbulb_rounded,
                        ),

                        const SizedBox(width: 10),

                        RetroButton(
                          text: "End Turn",
                          fontSize: 16,
                          iconSize: 30,
                          iconAtEnd: false,

                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),

                          onPressed: _endTurn,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                          icon: Icons.swap_horiz_rounded,
                        ),
                      ],
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBody(GameStateManager gameState) {
    if (gameState.gamePhase == GamePhase.characterSelection) {
      return _buildCharacterSelection(gameState);
    } else {
      return _buildGameBoard(gameState);
    }
  }

  Widget _buildCharacterSelection(GameStateManager gameState) {
    final isPlayer1Selecting = gameState.player1Character == null;
    final currentPlayerName = isPlayer1Selecting ? "Player 1" : "Player 2";

    return Container(
      color: Theme.of(context).colorScheme.tertiary,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (gameState.player1Character != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      SizedBox(width: 14),
                      Text(
                        "Player 1 picked a character",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    SizedBox(width: 14),
                    Text(
                      "$currentPlayerName picks a character",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: !_isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: gameState.allCharacters.length,
                    itemBuilder: (context, index) {
                      final character = gameState.allCharacters[index];
                      return _buildCharacterCard(
                        character,
                        isFlipped: false,
                        isSelectionMode: true,
                      );
                    },
                  )
                : SizedBox(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Loading Characters...",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard(GameStateManager gameState) {
    final currentFlippedCards = gameState.getCurrentFlippedCards();
    final selectedCharacter = gameState.getCurrentPlayerCharacter();
    final remainingCount = gameState.getRemainingCount();

    return Column(
      children: [
        //* TIP
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCharacterNameRevealed = !_isCharacterNameRevealed;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isCharacterNameRevealed
                          ? Theme.of(context).colorScheme.tertiary.withAlpha(50)
                          : Theme.of(
                              context,
                            ).colorScheme.tertiary.withAlpha(20),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiary.withAlpha(100),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isCharacterNameRevealed) ...[
                              Text(
                                "${gameState.getCurrentPlayerName()} chose ${selectedCharacter?.name ?? "Unknown"}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              Icon(
                                _isCharacterNameRevealed
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.tertiary.withAlpha(200),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Reveal chosen character",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.tertiary.withAlpha(200),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.tertiary,
                    width: 1,
                  ),
                ),
                child: Text(
                  "$remainingCount left",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        //* BOARD
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
              itemCount: gameState.allCharacters.length,
              itemBuilder: (context, index) {
                final character = gameState.allCharacters[index];
                final isFlipped = currentFlippedCards.contains(character.id);

                return _buildCharacterCard(
                  character,
                  isSelectionMode: false,
                  isFlipped: isFlipped,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(
    Character character, {
    required bool isFlipped,
    required bool isSelectionMode,
  }) {
    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          _selectCharacter(character);
        } else {
          _toggleFlipCard(character.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isFlipped
              ? Colors.grey.shade800
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedOpacity(
          opacity: isFlipped ? 0.3 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      character.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTree) {
                        debugPrint(error.toString());
                        return Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withAlpha(100),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withAlpha(100),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.tertiary,
                              ),
                              strokeCap: StrokeCap.round,
                              strokeWidth: 5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              //* CHARACTER NAME
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
      ),
    );
  }
}
