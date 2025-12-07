class User {
  final String id;
  final String username;
  final String? email;
  final DateTime? createdAt;

  User({required this.id, required this.username, this.email, this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"] as String,
      username: json["username"] as String,
      email: json["email"] as String?,
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "email": email,
      if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
    };
  }
}
