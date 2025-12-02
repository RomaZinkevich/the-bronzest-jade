import 'dart:io';

class Character {
  final String id;
  final String name;
  final String imageUrl;
  final File? imageFile;
  final String? uploadedFilename;

  Character({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.imageFile,
    this.uploadedFilename,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json["id"] as String,
      name: json["name"] as String,
      imageUrl: json["imageUrl"] as String,
      uploadedFilename: json["uploadedFilename"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "imageUrl": imageUrl,
      if (uploadedFilename != null) "uploadedFilename": uploadedFilename,
    };
  }

  Character copyWith({
    String? id,
    String? name,
    String? imageUrl,
    File? imageFile,
    String? uploadedFilename,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFile: imageFile ?? this.imageFile,
      uploadedFilename: uploadedFilename ?? this.uploadedFilename,
    );
  }
}
