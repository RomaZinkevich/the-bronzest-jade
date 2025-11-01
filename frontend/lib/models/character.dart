class Character {
  final String id;
  final String name;
  final String imageUrl;

  Character({required this.id, required this.name, required this.imageUrl});

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json["id"] as String,
      name: json["name"] as String,
      imageUrl: json["image_url"] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "image_url": imageUrl};
  }
}
