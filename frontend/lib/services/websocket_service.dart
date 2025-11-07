import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebsocketService {
  static const String wsUrl = 'https://guesswho.190304.xyz/ws';

  StompClient? _stompClient;
  bool _isConnected = false;

  String? _roomId;
  String? _playerId;

  final _messageController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<String> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  String get playerId => _playerId ?? "undefined";

  void connect(String roomId, String playerId) {
    _roomId = roomId;
    _playerId = playerId;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          debugPrint("WebSocket Error: $error");
          _isConnected = false;
          _connectionController.add(false);
          _errorController.add("Connection error: $error");
        },
        onStompError: (StompFrame frame) {
          debugPrint("STOMP error: ${frame.body}");
          _errorController.add("STOMP error: ${frame.body}");
        },
        onDisconnect: (StompFrame frame) {
          debugPrint("Disconnected");
          _isConnected = false;
          _connectionController.add(false);
        },
        stompConnectHeaders: {"playerId": playerId, "roomId": roomId},
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint("Connected to WebSocket");
    _isConnected = true;
    _connectionController.add(true);

    _stompClient!.subscribe(
      destination: "/topic/room.$_roomId",
      callback: (StompFrame frame) {
        if (frame.body != null) {
          debugPrint("Received message: ${frame.body}");
          _messageController.add(frame.body!);
        }
      },
    );

    _stompClient!.subscribe(
      destination: "/user/queue/errors",
      callback: (StompFrame frame) {
        if (frame.body != null) {
          debugPrint("Recieved error: ${frame.body}");
          _errorController.add(frame.body!);
        }
      },
    );

    sendJoin();
  }

  void sendJoin() {
    if (!_isConnected) {
      debugPrint("Cannot send join - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/join", body: "");
  }

  void sendReady() {
    if (!_isConnected) {
      debugPrint("Cannot send ready - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/ready", body: "");
  }

  void sendStart() {
    if (!_isConnected) {
      debugPrint("Cannot send start - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/start", body: "");
  }

  void sendQuestion(String question) {
    if (!_isConnected) {
      debugPrint("Cannot send question - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/question", body: question);
  }

  void sendAnswer(String answer) {
    if (!_isConnected) {
      debugPrint("Cannot send answer - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/question", body: answer);
  }

  void sendGuess(String characterId) {
    if (!_isConnected) {
      debugPrint("Cannot send guess - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/guess", body: characterId);
  }

  void disconnect() {
    if (_stompClient != null) {
      _stompClient!.deactivate();
      _stompClient = null;
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void dispose() {
    disconnect();

    _messageController.close();
    _errorController.close();
    _connectionController.close();
  }
}
