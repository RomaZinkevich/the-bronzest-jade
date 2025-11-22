class Character {
  final String id;
  final String name;
  final String imageUrl;

  Character({required this.id, required this.name, required this.imageUrl});

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json["id"] as String,
      name: json["name"] as String,
      imageUrl: json["imageUrl"] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "imageUrl": imageUrl};
  }
}
