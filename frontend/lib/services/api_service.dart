import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:guess_who/models/character_set.dart';
import 'package:guess_who/models/room.dart';
import 'package:guess_who/models/room_player.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://guesswho.190304.xyz/api';

  static Future<List<CharacterSet>> getCharacterSets() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/character-sets"),
        headers: {"Content-Type": "application/json"},
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
      final response = await http.get(
        Uri.parse("$baseUrl/character-sets/$id"),
        headers: {"Content-Type": "application/json"},
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
      final response = await http.post(
        Uri.parse("$baseUrl/rooms/$roomId/select-character"),
        headers: {"Content-Type": "application/json"},
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
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/images/upload"),
      );

      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Failed to upload image: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error uploading images: $e");
    }
  }

  static Future<CharacterSet> createCharacterSet(
    String name,
    String createdBy,
    bool isPublic,
    List<Map<String, String>> characters,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/character-sets"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": name,
          "createdBy": createdBy,
          "isPublic": isPublic,
          "characters": characters,
        }),
      );

      if (response.statusCode != 201) {
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
      final response = await http.post(
        Uri.parse("$baseUrl/rooms"),
        headers: {"Content-Type": "application/json"},
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
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/join/$roomCode'),
        headers: {'Content-Type': 'application/json'},
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
      debugPrint("$baseUrl/rooms/$roomId/leave");

      final response = await http.post(
        Uri.parse("$baseUrl/rooms/$roomId/leave"),
        headers: {"Content-Type": "application/json"},
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
}
