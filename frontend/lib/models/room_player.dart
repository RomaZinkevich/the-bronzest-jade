import 'package:guess_who/models/character.dart';

class RoomPlayer {
  final String id;
  final String? roomId;
  final String? userId;
  final bool isHost;
  final bool isReady;
  final Character? characterToGuess;
  final DateTime joinedAt;

  RoomPlayer({
    required this.id,
    this.roomId,
    this.userId,
    required this.isHost,
    required this.isReady,
    this.characterToGuess,
    required this.joinedAt,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    return RoomPlayer(
      id: json["id"] as String,

      roomId: json["roomId"] != null ? json["roomId"] as String : null,

      userId: json["userId"] != null ? json["userId"] as String : null,
      isHost: json["isHost"] as bool,
      isReady: json["isReady"] as bool,

      characterToGuess: json["characterToGuess"] != null
          ? Character.fromJson(json["characterToGuess"] as Map<String, dynamic>)
          : null,

      joinedAt: DateTime.parse(json["joinedAt"] as String),
    );
  }
}
