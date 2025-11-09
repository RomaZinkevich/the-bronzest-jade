import 'package:guess_who/models/character.dart';

class CharacterSet {
  final String id;
  final String name;
  final String createdBy;

  final bool isPublic;
  final DateTime createdAt;
  final List<Character> characters;

  CharacterSet({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.isPublic,
    required this.createdAt,
    required this.characters,
  });

  factory CharacterSet.fromJson(Map<String, dynamic> json) {
    return CharacterSet(
      id: json["id"] as String,
      name: json['name'] as String,
      createdBy: json['createdBy'] as String,
      isPublic: json['isPublic'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      characters: (json['characters'] as List<dynamic>)
          .map((c) => Character.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
