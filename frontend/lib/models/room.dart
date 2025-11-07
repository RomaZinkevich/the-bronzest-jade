import 'package:guess_who/models/character_set.dart';

enum RoomStatus { waiting, inProgress, finished }

class Room {
  final String id;
  final String roomCode;
  final String hostId;

  final RoomStatus status;
  final int maxPlayers;
  final CharacterSet? characterSet;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  Room({
    required this.id,
    required this.roomCode,
    required this.hostId,
    required this.status,
    required this.maxPlayers,

    this.characterSet,

    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json["id"] as String,
      roomCode: json["roomCode"] as String,
      hostId: json["hostId"] as String,
      status: RoomStatus.values.byName(json["status"] as String),
      maxPlayers: json["maxPlayers"] as int,

      characterSet: json["characterSet"] != null
          ? CharacterSet.fromJson(json["characterSet"] as Map<String, dynamic>)
          : null,

      createdAt: DateTime.parse(json['createdAt'] as String),

      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,

      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
    );
  }
}
