import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:guess_who/models/character_set.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/models/room_player.dart';
import 'package:guess_who/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://guesswho.190304.xyz/api';

  static Future<Map<String, String>> _getHeaders() async {
    final headers = {"Content-Type": "application/json"};
    final token = await AuthService.getToken();

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  static Future<List<CharacterSet>> getCharacterSets() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/character-sets"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CharacterSet.fromJson(json)).toList();
      } else {
        throw Exception(
          "Failed to load character sets: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching character sets: $e");
    }
  }

  static Future<CharacterSet> getCharacterSet(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/character-sets/$id"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return CharacterSet.fromJson(json.decode(response.body));
      } else {
        throw Exception("Failed to load character set: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching character set: $e");
    }
  }

  static Future<RoomPlayer> selectCharacter(
    String roomId,
    String playerId,
    String characterId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/rooms/$roomId/select-character"),
        headers: headers,
        body: json.encode({"playerId": playerId, "characterId": characterId}),
      );

      if (response.statusCode == 200) {
        return RoomPlayer.fromJson(json.decode(response.body));
      } else {
        throw Exception("Failed to select character: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error selecting character: $e");
    }
  }

  static Future<String> uploadImage(File imageFile) async {
    try {
      final token = await AuthService.getToken();
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/images/uploads"),
      );

      if (token != null && token.isNotEmpty) {
        request.headers["Authorization"] = "Bearer $token";
      }

      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        debugPrint(response.body);
        throw Exception("Failed to upload image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error uploading images: $e");
    }
  }

  static Future<void> deleteImage(String filename) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/images/$filename"),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete image: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error deleting image: $e");
    }
  }

  static Future<CharacterSet> createCharacterSet(
    String name,
    bool isPublic,
    List<Map<String, String>> characters,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/character-sets"),
        headers: headers,
        body: json.encode({
          "name": name,
          "isPublic": isPublic,
          "characters": characters,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception("Failed to create character set: ${response.body}");
      }

      final jsonBody = json.decode(response.body);
      return CharacterSet.fromJson(jsonBody);
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Something went wrong: $e");
    }
  }

  static Future<Room> createRoom(String hostId, String characterSetId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/rooms"),
        headers: headers,
        body: json.encode({"hostId": hostId, "characterSetId": characterSetId}),
      );

      if (response.statusCode == 200) {
        return Room.fromJson(json.decode(response.body));
      } else {
        throw Exception("Failed to create room: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error creating room: $e");
    }
  }

  static Future<Room> joinRoom(String roomCode, String playerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/join/$roomCode'),
        headers: headers,
        body: json.encode({'playerId': playerId}),
      );

      if (response.statusCode == 200) {
        return Room.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to join room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error joining room: $e');
    }
  }

  static Future<Room?> leaveRoom(String roomId, String playerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/rooms/$roomId/leave"),
        headers: headers,
        body: json.encode({"playerId": playerId}),
      );

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.isEmpty || body == "null") {
          return null;
        }
        return Room.fromJson(json.decode(body));
      } else {
        debugPrint("${response.statusCode}");
        throw Exception("Failed to leave room: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error leaving room: $e");
    }
  }

  static Future<Map<String, dynamic>> createGuestUser() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/guest"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to create guest user: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error creating guest user: $e");
    }
  }
}
