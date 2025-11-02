import 'package:flutter/material.dart';
import 'package:guess_who/data/game_data.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/widgets/retro_button.dart';

enum GamePhase { characterSelection, player1Turn, player2Turn, gameOver }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GamePhase _currentPhase = GamePhase.characterSelection;
  List<Character> _allCharacters = [];

  final Set<String> _player1FlippedCards = {};
  final Set<String> _player2FlippedCards = {};

  Character? _player1SelectedCharacter;
  Character? _player2SelectedCharacter;

  String _currentPlayer = "Player 1";
  String? _winner;

  bool _isLoading = false;
  bool _isCharacterNameRevealed = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final characters = await GameData.fetchCharacters();
      setState(() {
        _allCharacters = characters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching characters: $e");
    }
  }

  void _selectCharacter(Character character, bool isPlayer1) {
    if (_currentPhase != GamePhase.characterSelection) return;

    setState(() {
      if (isPlayer1) {
        _player1SelectedCharacter = character;
      } else {
        _player2SelectedCharacter = character;
      }

      if (_player1SelectedCharacter != null &&
          _player2SelectedCharacter != null) {
        _currentPhase = GamePhase.player1Turn;
        _currentPlayer = "Player 1";
      }
    });
  }

  void _toggleFlipCard(String characterId) {
    setState(() {
      switch (_currentPhase) {
        case GamePhase.player1Turn:
          if (_player1FlippedCards.contains(characterId)) {
            _player1FlippedCards.remove(characterId);
          } else {
            _player1FlippedCards.add(characterId);
          }

          break;
        case GamePhase.player2Turn:
          if (_player2FlippedCards.contains(characterId)) {
            _player2FlippedCards.remove(characterId);
          } else {
            _player2FlippedCards.add(characterId);
          }

          break;
        default:
          break;
      }
    });
  }

  void _endTurn() {
    setState(() {
      switch (_currentPhase) {
        case GamePhase.player1Turn:
          _currentPhase = GamePhase.player2Turn;
          _currentPlayer = "Player 2";
          break;
        case GamePhase.player2Turn:
          _currentPhase = GamePhase.player1Turn;
          _currentPlayer = "Player 1";
          break;
        default:
          break;
      }

      _isCharacterNameRevealed = false;
    });
  }

  void _makeGuess() {
    final currentFlippedCards = _currentPhase == GamePhase.player1Turn
        ? _player1FlippedCards
        : _player2FlippedCards;

    final availableCharacters = _allCharacters
        .where((c) => !currentFlippedCards.contains(c.id))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          title: Text(
            "Make Your Guess",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: availableCharacters.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No characters available! Flip some back to make a guess.",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCharacters.length,
                    itemBuilder: (context, index) {
                      final character = availableCharacters[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.tertiary,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              character.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            character.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _checkGuess(character);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
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

  void _checkGuess(Character guessedCharacter) {
    final opponentCharacter = _currentPhase == GamePhase.player1Turn
        ? _player2SelectedCharacter
        : _player1SelectedCharacter;

    if (guessedCharacter.id == opponentCharacter?.id) {
      setState(() {
        _winner = _currentPlayer;
        _currentPhase = GamePhase.gameOver;
      });

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
                'Game Over!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            '$_winner wins the game',
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
                'Play Again',
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
                'Exit to Menu',
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
                'Wrong Guess!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            '$_currentPlayer guessed incorrectly and loses!',
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
                setState(() {
                  _winner = _currentPlayer == 'Player 1'
                      ? 'Player 2'
                      : 'Player 1';
                  _currentPhase = GamePhase.gameOver;
                });
                _showWinnerDialog();
              },
              child: Text(
                'OK',
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
      _currentPhase = GamePhase.characterSelection;

      _player1SelectedCharacter = null;
      _player2SelectedCharacter = null;

      _player1FlippedCards.clear();
      _player2FlippedCards.clear();

      _winner = null;
      _currentPlayer = "Player 1";

      _isCharacterNameRevealed = false;

      _initializeGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.tertiary),
        title: Text(
          _currentPhase == GamePhase.characterSelection
              ? "Select Your Character"
              : "$_currentPlayer's Turn",
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 20,
          ),
        ),
        // actions: [
        //   if (_currentPhase != GamePhase.characterSelection &&
        //       _currentPhase != GamePhase.gameOver)
        //     Padding(
        //       padding: const EdgeInsets.only(right: 16.0),
        //       child: Center(
        //         child: Container(
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 12,
        //             vertical: 6,
        //           ),
        //           decoration: BoxDecoration(
        //             color: Theme.of(context).colorScheme.secondary,
        //             borderRadius: BorderRadius.circular(20),
        //             border: Border.all(
        //               color: Theme.of(context).colorScheme.tertiary,
        //               width: 2,
        //             ),
        //           ),
        //           child: Text(
        //             _currentPlayer,
        //             style: TextStyle(
        //               color: Theme.of(context).colorScheme.tertiary,
        //               fontSize: 14,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        // ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
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
        child:
            _currentPhase != GamePhase.characterSelection &&
                _currentPhase != GamePhase.gameOver
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RetroButton(
                    text: "Make Guess",
                    onPressed: _makeGuess,
                    fontSize: 16,
                    iconSize: 30,
                    iconAtEnd: false,

                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.tertiary,

                    icon: Icons.lightbulb_rounded,
                  ),
                  const SizedBox(width: 10),
                  RetroButton(
                    text: "End Turn",
                    fontSize: 16,
                    iconSize: 30,
                    iconAtEnd: false,

                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                    onPressed: _endTurn,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.tertiary,
                    icon: Icons.swap_horiz_rounded,
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentPhase) {
      case GamePhase.characterSelection:
        return _buildCharacterSelection();
      case GamePhase.player1Turn:
      case GamePhase.player2Turn:
      case GamePhase.gameOver:
        return _buildGameBoard();
    }
  }

  Widget _buildCharacterSelection() {
    final isPlayer1Selecting = _player1SelectedCharacter == null;
    final currentPlayerName = isPlayer1Selecting ? "Player 1" : "Player 2";

    return Column(
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
              if (_player1SelectedCharacter != null) ...[
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
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allCharacters.length,
                  itemBuilder: (context, index) {
                    final character = _allCharacters[index];
                    return _buildCharacterCard(
                      character,
                      isPlayer1Selecting,
                      isSelectionMode: true,
                    );
                  },
                )
              : SizedBox(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    final currentFlippedCards =
        _currentPhase == GamePhase.player1Turn ||
            _currentPhase == GamePhase.gameOver
        ? _player1FlippedCards
        : _player2FlippedCards;

    final selectedCharacter =
        _currentPhase == GamePhase.player1Turn ||
            _currentPhase == GamePhase.gameOver
        ? _player1SelectedCharacter
        : _player2SelectedCharacter;

    final remainingCount = _allCharacters.length - currentFlippedCards.length;

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
                                "$_currentPlayer chose ${selectedCharacter?.name ?? "Unknown"}",
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
              itemCount: _allCharacters.length,
              itemBuilder: (context, index) {
                final character = _allCharacters[index];
                final isFlipped = currentFlippedCards.contains(character.id);
                return _buildCharacterCard(
                  character,
                  false,
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
    Character character,
    bool isPlayer1Selecting, {
    required bool isSelectionMode,
    bool isFlipped = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          _selectCharacter(character, isPlayer1Selecting);
        } else if (_currentPhase != GamePhase.gameOver) {
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
                          color: Theme.of(context).colorScheme.primary,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.tertiary,
                              ),
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
