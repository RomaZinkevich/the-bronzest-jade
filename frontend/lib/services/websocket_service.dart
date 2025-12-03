import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guess_who/services/auth_service.dart';
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

  StompUnsubscribe? _roomSubscription;
  StompUnsubscribe? _errorSubscription;

  Stream<String> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  String get playerId => _playerId ?? "undefined";

  void _addToMessageStream(String message) {
    if (!_messageController.isClosed) {
      _messageController.sink.add(message);
    }
  }

  void _addToErrorStream(String error) {
    if (!_errorController.isClosed) {
      _errorController.sink.add(error);
    }
  }

  void _addToConnectionStream(bool connected) {
    if (!_connectionController.isClosed) {
      _connectionController.sink.add(connected);
    }
  }

  Future<void> connect(String roomId, String playerId) async {
    _roomId = roomId;
    _playerId = playerId;

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint("No authentication token found");
      _addToErrorStream("Authentication required");
      return;
    }

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          debugPrint("WebSocket Error: $error");
          _isConnected = false;
          _addToConnectionStream(false);
          _addToErrorStream(error?.toString() ?? "WebSocketError");
        },
        onStompError: (StompFrame frame) {
          debugPrint("STOMP error: ${frame.body}");
          _addToErrorStream("STOMP error: ${frame.body}");
        },
        onDisconnect: (StompFrame frame) {
          debugPrint("Disconnected");
          _isConnected = false;
          _addToConnectionStream(false);
        },
        stompConnectHeaders: {"roomId": roomId},
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint("Connected to WebSocket");
    _isConnected = true;
    _addToConnectionStream(true);

    _subscribeToTopics();
    sendJoin();
  }

  void _subscribeToTopics() {
    if (_stompClient == null || !_isConnected) {
      debugPrint("Cannot subscribe - not connected");
      return;
    }

    if (_roomSubscription != null) {
      debugPrint("Already subscribed to topics.");
      return;
    } else {
      final roomTopic = "/topic/room.$_roomId";
      debugPrint("[WS] Subscribing to $roomTopic");

      _roomSubscription = _stompClient!.subscribe(
        destination: "/topic/room.$_roomId",
        callback: (StompFrame frame) {
          if (frame.body != null) {
            debugPrint("[WS] Received message: ${frame.body}");
            _addToMessageStream(frame.body!);
          } else {
            debugPrint('[WS] Received frame with empty body on $roomTopic');
          }
        },
      );
    }

    if (_errorSubscription != null) {
      debugPrint('[WS] Already subscribed to error queue.');
    } else {
      debugPrint('[WS] Subscribing to /user/queue/errors');
      _errorSubscription = _stompClient!.subscribe(
        destination: "/user/queue/errors",
        callback: (StompFrame frame) {
          if (frame.body != null) {
            debugPrint('[WS] Received error: ${frame.body}');
            _addToErrorStream(frame.body!);
          }
        },
      );
    }
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

    String formattedMessage = " asked: $question";
    _stompClient!.send(destination: "/app/question", body: formattedMessage);
  }

  void sendAnswer(String answer) {
    if (!_isConnected) {
      debugPrint("Cannot send answer - not connected");
      return;
    }

    String formattedMessage = " answered: $answer";
    _stompClient!.send(destination: "/app/answer", body: formattedMessage);
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
      _roomSubscription?.call();
      _errorSubscription?.call();
      _roomSubscription = null;
      _errorSubscription = null;

      _stompClient!.deactivate();
      _stompClient = null;
      _isConnected = false;
      _addToConnectionStream(false);
    }
  }

  void dispose() {
    disconnect();

    _messageController.close();
    _errorController.close();
    _connectionController.close();
  }
}
