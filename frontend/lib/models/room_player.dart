import 'package:guess_who/models/character.dart';

class RoomPlayer {
  final String id;
  final String roomId;
  final String userId;
  final bool isHost;
  final bool isReady;
  final Character? characterToGuess;
  final DateTime joinedAt;

  RoomPlayer({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.isHost,
    required this.isReady,
    this.characterToGuess,
    required this.joinedAt,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    return RoomPlayer(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      userId: json['userId'] as String,
      isHost: json['isHost'] as bool,
      isReady: json['isReady'] as bool,

      characterToGuess: json['characterToGuess'] != null
          ? Character.fromJson(json['characterToGuess'] as Map<String, dynamic>)
          : null,

      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
