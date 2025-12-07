import 'package:guess_who/models/character.dart';

class CharacterSetDraft {
  final String id;
  final String name;
  final List<Character> characters;
  final bool isPublic;
  final DateTime lastModified;

  CharacterSetDraft({
    required this.id,
    required this.name,
    required this.characters,
    required this.isPublic,
    required this.lastModified,
  });

  factory CharacterSetDraft.fromJson(Map<String, dynamic> json) {
    return CharacterSetDraft(
      id: json["id"] as String,
      name: json["name"] as String,
      characters: (json["characters"] as List<dynamic>)
          .map((c) => Character.fromJson(c as Map<String, dynamic>))
          .toList(),
      isPublic: json["isPublic"] as bool,
      lastModified: DateTime.parse(json["lastModified"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "characters": characters.map((c) => c.toJson()).toList(),
      "isPublic": isPublic,
      "lastModified": lastModified.toIso8601String(),
    };
  }

  CharacterSetDraft copyWith({
    String? id,
    String? name,
    List<Character>? characters,
    bool? isPublic,
    DateTime? lastModified,
  }) {
    return CharacterSetDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      characters: characters ?? this.characters,
      isPublic: isPublic ?? this.isPublic,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  int get characterCount => characters.length;
  bool get isComplete => characterCount == 16;
}
