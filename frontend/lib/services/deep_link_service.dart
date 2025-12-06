import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService extends ChangeNotifier {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  String? _pendingRoomCode;
  String? get pendingRoomCode => _pendingRoomCode;

  void setPendingRoomCode(String code) {
    _pendingRoomCode = code;
    notifyListeners();
  }

  void clearPendingRoomCode() {
    _pendingRoomCode = null;
    notifyListeners();
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
    if (uri.host == "join" ||
        uri.path == "/join" ||
        uri.path.contains("join")) {
      final roomCode = uri.queryParameters["code"];

      if (roomCode != null && roomCode.isNotEmpty) {
        setPendingRoomCode(roomCode);
        debugPrint("Room code extracted and stored: $roomCode");
      } else {
        debugPrint("No 'code' parameter found in URI");
      }
    } else {
      debugPrint("URI doesn't match join pattern");
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
