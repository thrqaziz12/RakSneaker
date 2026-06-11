// =============================================================================
// user_model.dart
// Model data untuk akun user — disimpan di tabel SQLite 'users'.
// =============================================================================

class UserModel {
  final int? id;
  final String username;
  final String email;
  final String encryptedPassword;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.encryptedPassword,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'email': email,
        'encryptedPassword': encryptedPassword,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        username: map['username'] as String,
        email: map['email'] as String,
        encryptedPassword: map['encryptedPassword'] as String,
      );
}
