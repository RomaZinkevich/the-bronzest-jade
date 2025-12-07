import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guess_who/services/auth_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebsocketService {
  static const String wsUrl = 'https://guesswho.190304.xyz/ws';
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);

  StompClient? _stompClient;
  bool _isConnected = false;
  bool _isManualDisconnect = false;
  int _reconnectAttempts = 0;

  String? _roomId;
  String? _playerId;
  String? _token;

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
    _isManualDisconnect = false;

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint("[WS] No authentication token found");
      _addToErrorStream("Authentication required");
      return;
    }

    _token = token;
    _reconnectAttempts = 0;
    _createStompClient();
  }

  void _createStompClient() {
    if (_isManualDisconnect) {
      debugPrint("[WS] Manual disconnect active, not creating client");
      return;
    }

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: "$wsUrl?token=$_token",
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          debugPrint("[WS] WebSocket Error: $error");
          _isConnected = false;
          _addToConnectionStream(false);
          _handleDisconnection();
        },
        onStompError: (StompFrame frame) {
          debugPrint("[WS] STOMP error: ${frame.body}");
          _addToErrorStream("STOMP error: ${frame.body}");
        },
        onDisconnect: (StompFrame frame) {
          debugPrint("[WS] Disconnected from server");
          _isConnected = false;
          _addToConnectionStream(false);
          _unsubscribeFromTopics();
          _handleDisconnection();
        },
        stompConnectHeaders: {"roomId": _roomId!},
      ),
    );

    _stompClient!.activate();
  }

  void _handleDisconnection() {
    if (_isManualDisconnect) {
      debugPrint("[WS] Manual disconnect, not attempting reconnect");
      return;
    }

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;

      debugPrint(
        "[WS] Attempting reconnect ($_reconnectAttempts/$maxReconnectAttempts)...",
      );

      Future.delayed(reconnectDelay, () {
        if (!_isManualDisconnect && !isConnected) {
          _createStompClient();
        }
      });
    } else {
      debugPrint("[WS] MAx reconnection attempts reached");
      _addToErrorStream("Connection lost. Please try again.");
    }
  }

  void _onConnect(StompFrame frame) {
    debugPrint("[WS] Connected to WebSocket successfully");
    _isConnected = true;
    _reconnectAttempts = 0;
    _addToConnectionStream(true);

    _subscribeToTopics();
    sendJoin();
  }

  void _subscribeToTopics() {
    if (_stompClient == null || !_isConnected) {
      debugPrint("[WS] Cannot subscribe - not connected");
      return;
    }

    _unsubscribeFromTopics();

    final roomTopic = "/topic/room.$_roomId";
    debugPrint("[WS] Subscribing to $roomTopic");

    _roomSubscription = _stompClient!.subscribe(
      destination: roomTopic,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          debugPrint("[WS] Received message: ${frame.body}");
          _addToMessageStream(frame.body!);
        } else {
          debugPrint('[WS] Received frame with empty body on $roomTopic');
        }
      },
    );

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

  void _unsubscribeFromTopics() {
    if (_roomSubscription != null) {
      _roomSubscription?.call();
      _roomSubscription = null;

      debugPrint("[WS] Unsubscribed from room topic");
    }

    if (_errorSubscription != null) {
      _errorSubscription?.call();
      _errorSubscription = null;
      debugPrint("[WS] Unsubscribed from error queue");
    }
  }

  void sendJoin() {
    if (!_isConnected || _stompClient == null) {
      debugPrint("Cannot send join - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/join", body: "");
  }

  void sendReady() {
    if (!_isConnected || _stompClient == null) {
      debugPrint("Cannot send ready - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/ready", body: "");
  }

  void sendStart() {
    if (!_isConnected || _stompClient == null) {
      debugPrint("Cannot send start - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/start", body: "");
  }

  void sendQuestion(String question) {
    if (!_isConnected || _stompClient == null) {
      debugPrint("Cannot send question - not connected");
      return;
    }

    String formattedMessage = " asked: $question";
    _stompClient!.send(destination: "/app/question", body: formattedMessage);
  }

  void sendAnswer(String answer) {
    if (!_isConnected || _stompClient == null) {
      debugPrint("Cannot send answer - not connected");
      return;
    }

    String formattedMessage = " answered: $answer";
    _stompClient!.send(destination: "/app/answer", body: formattedMessage);
  }

  void sendGuess(String characterId) {
    if (!_isConnected || _stompClient == null) {
      debugPrint("Cannot send guess - not connected");
      return;
    }

    _stompClient!.send(destination: "/app/guess", body: characterId);
  }

  void disconnect() {
    debugPrint("[WS] Manual disconnect initiated");
    _isManualDisconnect = true;
    _reconnectAttempts = 0;

    _unsubscribeFromTopics();

    if (_stompClient != null) {
      _stompClient!.deactivate();
      _stompClient = null;
    }

    _isConnected = false;
    _addToConnectionStream(false);
  }

  void dispose() {
    debugPrint("[WS] Disposing WebSocket service");
    disconnect();

    _messageController.close();
    _errorController.close();
    _connectionController.close();
  }
}
