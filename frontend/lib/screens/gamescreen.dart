import 'package:flutter/material.dart';
import 'package:guess_who/data/game_data.dart';
import 'package:guess_who/models/character.dart';

enum GamePhase { characterSelection, player1Turn, player2Turn, gameOver }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GamePhase _currentPhase = GamePhase.characterSelection;
  List<Character> _allCharacters = [];

  Set<String> _player1FlippedCards = {};
  Set<String> _player2FlippedCards = {};

  Character? _player1SelectedCharacter;
  Character? _player2SelectedCharacter;

  String _currentPlayer = "Player 1";
  String? _winner;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    setState(() {
      // TODO: Replace with API call
      _allCharacters = GameData.getSampleCharacters();
    });
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
              width: 4,
            ),
          ),
          title: Text(
            "Make Your Guess",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          content: Container(
            width: double.maxFinite,
            child: availableCharacters.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No characters available!\nFlip some back to make a guess.",
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
              width: 4,
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
        actions: [
          if (_currentPhase != GamePhase.characterSelection &&
              _currentPhase != GamePhase.gameOver)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _currentPlayer,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
          _currentPhase != GamePhase.characterSelection &&
              _currentPhase != GamePhase.gameOver
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: _makeGuess,
                  heroTag: "guess",
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                  label: const Text("Make Guess"),
                  icon: const Icon(Icons.lightbulb_rounded),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  onPressed: _endTurn,
                  heroTag: "endTurn",
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                  label: const Text("End Turn"),
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              ],
            )
          : null,
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
              if (_player1SelectedCharacter != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              Expanded(
                child: Text(
                  "$currentPlayerName: Pick your secret character",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Character: ",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiary.withAlpha(200),
                          ),
                        ),
                        Text(
                          selectedCharacter?.name ?? "No Name",
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      "$remainingCount left",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Ask questions and tap to flip cards",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.tertiary.withAlpha(240),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
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
            color: Theme.of(context).colorScheme.primary,
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
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      character.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTree) {
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
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
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
