import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;

  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  String? _pendingRoomCode;
  String? get pendingRoomCode => _pendingRoomCode;

  void clearPendingRoomCode() {
    _pendingRoomCode = null;
  }

  Future<void> initialize() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint("Deep link error: $err");
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Recieved deep link: $uri");
    if (uri.path == "/join" || uri.host == "join") {
      final roomCode = uri.queryParameters["code"];
      if (roomCode != null && roomCode.isNotEmpty) {
        _pendingRoomCode = roomCode;
        debugPrint("Extracted room code: $_pendingRoomCode");
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
