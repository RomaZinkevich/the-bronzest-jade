import 'package:flutter/foundation.dart';
import 'package:guess_who/models/character.dart';

enum GameMode { local, online }

enum GamePhase { characterSelection, waitingForOpponent, playing, gameOver }

class GameStateManager extends ChangeNotifier {
  GameMode _gameMode = GameMode.local;
  GameMode get gameMode => _gameMode;

  GamePhase _currentPhase = GamePhase.characterSelection;
  GamePhase get gamePhase => _currentPhase;

  List<Character> _allCharacters = [];
  List<Character> get allCharacters => _allCharacters;

  String? _playerId;
  String? get playerId => _playerId;

  String? _opponentId;
  String? get opponentId => _opponentId;

  bool _isHost = false;
  bool get isHost => _isHost;

  bool _isMyTurn = false;
  bool get isMyTurn => _isMyTurn;

  //* SELECTED CHARACTER
  Character? _myCharacter;
  Character? get myCharacter => _myCharacter;

  Character? _opponentCharacter;
  Character? get opponentCharacter => _opponentCharacter;

  final Set<String> _myFlippedCards = {};
  Set<String> get myFlippedCards => _myFlippedCards;

  final Set<String> _opponentFlippedCards = {};
  Set<String> get opponentFlippedCards => _opponentFlippedCards;

  String? _winner;
  String? get winner => _winner;

  bool _isReady = false;
  bool get isReady => _isReady;

  bool _isOpponentReady = false;
  bool get isOpponentReady => _isOpponentReady;

  String? _roomId;
  String? get roomId => _roomId;

  String? _roomCode;
  String? get roomCode => _roomCode;

  //* LOCAL PLAY
  bool _isPlayer1 = true;
  bool get isPlayer1 => _isPlayer1;

  Character? _player1Character;
  Character? get player1Character => _player1Character;

  Character? _player2Character;
  Character? get player2Character => _player2Character;

  final Set<String> _player1FlippedCards = {};
  Set<String> get player1FlippedCards => _player1FlippedCards;

  final Set<String> _player2FlippedCards = {};
  Set<String> get player2FlippedCards => _player2FlippedCards;

  void initializeGame({
    required GameMode mode,
    required List<Character> characters,
    String? playerId,
    String? roomId,
    String? roomCode,
    bool isHost = false,
  }) {
    _gameMode = mode;
    _allCharacters = characters;
    _roomId = roomId;
    _roomCode = roomCode;
    _isHost = isHost;
    _currentPhase = GamePhase.characterSelection;

    _myCharacter = null;
    _opponentCharacter = null;
    _player1Character = null;
    _player2Character = null;
    _myFlippedCards.clear();
    _opponentFlippedCards.clear();

    _winner = null;
    _isReady = false;
    _isOpponentReady = false;
    _isMyTurn = false;

    //* LOCAL PLAY
    _player1FlippedCards.clear();
    _player2FlippedCards.clear();
    _isPlayer1 = true;

    notifyListeners();
  }

  void selectMyCharacter(Character character) {
    if (_gameMode == GameMode.online) {
      _myCharacter = character;
      _currentPhase = GamePhase.waitingForOpponent;

      notifyListeners();
      return;
    }

    if (_isPlayer1) {
      _player1Character = character;
      _isPlayer1 = false;

      _switchGamePhaseOnPlayersReady();
    } else {
      _player2Character = character;
      _switchGamePhaseOnPlayersReady();
    }

    notifyListeners();
  }

  void _switchGamePhaseOnPlayersReady() {
    if (_player1Character != null && _player2Character != null) {
      _currentPhase = GamePhase.playing;
      _isPlayer1 = true;
    }
  }

  void setOpponentCharacter(Character character) {
    _opponentCharacter = character;
    notifyListeners();
  }

  void setReady(bool ready) {
    _isReady = ready;
    notifyListeners();
  }

  void setOpponentReady(bool ready) {
    _isOpponentReady = ready;
    notifyListeners();
  }

  void startOnlineGame() {
    _currentPhase = GamePhase.playing;
    _isMyTurn = _isHost;
    debugPrint("My Turn?: $_isMyTurn (isHost: $_isHost)");
    notifyListeners();
  }

  void toggleFlipCard(String characterId) {
    if (_gameMode == GameMode.online) {
      if (_myFlippedCards.contains(characterId)) {
        _myFlippedCards.remove(characterId);
      } else {
        _myFlippedCards.add(characterId);
      }

      notifyListeners();
      return;
    }

    if (_isPlayer1) {
      if (_player1FlippedCards.contains(characterId)) {
        _player1FlippedCards.remove(characterId);
      } else {
        _player1FlippedCards.add(characterId);
      }
    } else {
      if (_player1FlippedCards.contains(characterId)) {
        _player1FlippedCards.remove(characterId);
      } else {
        _player1FlippedCards.add(characterId);
      }
    }

    notifyListeners();
  }

  void endLocalTurn() {
    _isPlayer1 = !_isPlayer1;
    notifyListeners();
  }

  void switchTurn() {
    _isMyTurn = !_isMyTurn;
    notifyListeners();
  }

  bool makeGuess(Character guessedCharacter) {
    bool isCorrect = false;

    if (_gameMode == GameMode.online) {
      isCorrect = guessedCharacter.id == _opponentCharacter?.id;

      if (isCorrect) {
        _winner = "You";
        _currentPhase = GamePhase.gameOver;
      } else {
        _winner = "Opponent";
        _currentPhase = GamePhase.gameOver;
      }

      notifyListeners();
      return isCorrect;
    }

    final targetCharacter = _isPlayer1 ? _player2Character : _player1Character;
    isCorrect = guessedCharacter.id == targetCharacter?.id;

    if (isCorrect) {
      _winner = _isPlayer1 ? "Player 1" : "Player 2";
      _currentPhase = GamePhase.gameOver;
    } else {
      _winner = _isPlayer1 ? "Player 2" : "Player 1";
      _currentPhase = GamePhase.gameOver;
    }

    notifyListeners();
    return isCorrect;
  }

  void resetGame() {
    _currentPhase = GamePhase.characterSelection;

    _myCharacter = null;
    _opponentCharacter = null;
    _player1Character = null;
    _player2Character = null;
    _myFlippedCards.clear();
    _opponentFlippedCards.clear();

    _winner = null;
    _isReady = false;
    _isOpponentReady = false;
    _isMyTurn = false;

    //* LOCAL PLAY
    _player1FlippedCards.clear();
    _player2FlippedCards.clear();
    _isPlayer1 = true;

    notifyListeners();
  }

  Set<String> getCurrentFlippedCards() {
    if (_gameMode == GameMode.online) {
      return _myFlippedCards;
    }

    return _isPlayer1 ? _player1FlippedCards : _player2FlippedCards;
  }

  Character? getCurrentPlayerCharacter() {
    if (_gameMode == GameMode.online) {
      return _myCharacter;
    }

    return _isPlayer1 ? _player1Character : _player2Character;
  }

  String getCurrentPlayerName() {
    if (_gameMode == GameMode.online) {
      return _isMyTurn ? "Your Turn" : "Opponent's Turn";
    }

    return _isPlayer1 ? "Player 1" : "Player 2";
  }

  bool get bothPlayersSelectedLocal =>
      _player1Character != null && _player2Character != null;

  bool get bothPlayersReady => _isReady && _isOpponentReady;

  List<Character> getAvailableCharacters() {
    final flippedCards = getCurrentFlippedCards();
    return _allCharacters.where((c) => !flippedCards.contains(c.id)).toList();
  }

  int getRemainingCount() {
    final flippedCards = getCurrentFlippedCards();
    return _allCharacters.length - flippedCards.length;
  }
}
