import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/services/websocket_service.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
