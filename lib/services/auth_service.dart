import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../core/encryption_helper.dart';

class AuthService {
  static const String _boxName = 'users';
  static const String _settingsBox = 'settings';
  static const String _lastUsernameKey = 'lastLoggedInUsername';

  Box<UserModel> get _usersBox => Hive.box<UserModel>(_boxName);
  Box<dynamic> get _settings => Hive.box<dynamic>(_settingsBox);

  /// Simpan username terakhir yang berhasil login (untuk login biometrik)
  Future<void> saveLastLoggedInUsername(String username) async {
    await _settings.put(_lastUsernameKey, username);
  }

  /// Ambil username terakhir yang berhasil login
  /// Return null jika belum pernah login sebelumnya
  String? getLastLoggedInUsername() {
    return _settings.get(_lastUsernameKey) as String?;
  }

  /// Register user baru
  /// Return null jika berhasil, atau pesan error jika gagal
  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (username.trim().isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }

    final existingUser = _usersBox.values
        .where((u) => u.username.toLowerCase() == username.trim().toLowerCase())
        .isNotEmpty;
    if (existingUser) {
      return 'Username sudah digunakan';
    }

    final existingEmail = _usersBox.values
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
        .isNotEmpty;
    if (existingEmail) {
      return 'Email sudah digunakan';
    }

    final encryptedPassword = EncryptionHelper.encryptPassword(password);
    final newUser = UserModel(
      username: username.trim(),
      email: email.trim().toLowerCase(),
      encryptedPassword: encryptedPassword,
    );
    await _usersBox.add(newUser);
    return null;
  }

  /// Login user dengan username + password
  /// Return UserModel jika berhasil, null jika gagal
  UserModel? login({
    required String username,
    required String password,
  }) {
    if (username.trim().isEmpty || password.isEmpty) return null;

    try {
      final user = _usersBox.values.firstWhere(
        (u) => u.username.toLowerCase() == username.trim().toLowerCase(),
      );

      final decryptedPassword =
          EncryptionHelper.decryptPassword(user.encryptedPassword);

      if (decryptedPassword == password) {
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cari user berdasarkan username (tanpa validasi password)
  /// Digunakan untuk login biometrik
  UserModel? getUserByUsername(String username) {
    if (username.trim().isEmpty) return null;

    try {
      return _usersBox.values.firstWhere(
        (u) => u.username.toLowerCase() == username.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
