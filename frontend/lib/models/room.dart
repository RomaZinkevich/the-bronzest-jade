import 'package:guess_who/models/character_set.dart';
import 'package:guess_who/models/user.dart';

enum RoomStatus { waiting, inProgress, finished }

//? SHOULD WE JUST USE STRING FOR ROOM STATUS
extension RoomStatusX on RoomStatus {
  static RoomStatus fromApi(String value) {
    switch (value) {
      case "WAITING":
        return RoomStatus.waiting;
      case 'IN_PROGRESS':
        return RoomStatus.inProgress;
      case 'FINISHED':
        return RoomStatus.finished;
      default:
        throw ArgumentError('Unknown RoomStatus: $value');
    }
  }

  String toApi() {
    switch (this) {
      case RoomStatus.waiting:
        return 'WAITING';
      case RoomStatus.inProgress:
        return 'IN_PROGRESS';
      case RoomStatus.finished:
        return 'FINISHED';
    }
  }
}

class Room {
  final String id;
  final String roomCode;
  final User host;

  final RoomStatus status;
  final int maxPlayers;
  final CharacterSet? characterSet;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  Room({
    required this.id,
    required this.roomCode,
    required this.host,
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
      host: User.fromJson(json["host"] as Map<String, dynamic>),
      status: RoomStatusX.fromApi(json["status"] as String),
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
