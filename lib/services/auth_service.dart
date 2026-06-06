import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../core/encryption_helper.dart';

class AuthService {
  static const String _boxName = 'users';

  Box<UserModel> get _usersBox => Hive.box<UserModel>(_boxName);

  /// Register user baru
  /// Return null jika berhasil, atau pesan error jika gagal
  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    // Validasi username tidak boleh kosong
    if (username.trim().isEmpty) {
      return 'Username tidak boleh kosong';
    }
    // Validasi email sederhana
    if (!email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid';
    }
    // Validasi password minimal 6 karakter
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }

    // Cek apakah username sudah ada
    final existingUser = _usersBox.values
        .where((u) => u.username.toLowerCase() == username.trim().toLowerCase())
        .isNotEmpty;

    if (existingUser) {
      return 'Username sudah digunakan';
    }

    // Cek apakah email sudah ada
    final existingEmail = _usersBox.values
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
        .isNotEmpty;

    if (existingEmail) {
      return 'Email sudah digunakan';
    }

    // Enkripsi password sebelum disimpan
    final encryptedPassword = EncryptionHelper.encryptPassword(password);

    // Simpan user ke Hive
    final newUser = UserModel(
      username: username.trim(),
      email: email.trim().toLowerCase(),
      encryptedPassword: encryptedPassword,
    );
    await _usersBox.add(newUser);

    return null; // null = sukses
  }

  /// Login user
  /// Return UserModel jika berhasil, null jika gagal
  UserModel? login({
    required String username,
    required String password,
  }) {
    if (username.trim().isEmpty || password.isEmpty) return null;

    try {
      // Cari user berdasarkan username
      final user = _usersBox.values.firstWhere(
        (u) => u.username.toLowerCase() == username.trim().toLowerCase(),
      );

      // Dekripsi dan bandingkan password
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
}
