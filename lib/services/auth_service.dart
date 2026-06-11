// =============================================================================
// auth_service.dart
// Service autentikasi menggunakan SQLite.
//
// Semua data user (register, login, lookup) mengakses tabel 'users'.
// lastLoggedInUsername disimpan di tabel 'settings' (key-value).
// =============================================================================

import 'package:sqflite/sqflite.dart';
import '../core/database_helper.dart';
import '../core/encryption_helper.dart';
import '../models/user_model.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  // ──────────────────────────────────────────────
  // Last logged-in username (untuk biometrik)
  // ──────────────────────────────────────────────

  /// Simpan username terakhir yang berhasil login.
  Future<void> saveLastLoggedInUsername(String username) async {
    final db = await _db;
    // Pastikan tabel settings ada (dibuat jika belum ada)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.insert(
      'settings',
      {'key': 'lastLoggedInUsername', 'value': username},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil username terakhir yang berhasil login.
  Future<String?> getLastLoggedInUsername() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['lastLoggedInUsername'],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  // ──────────────────────────────────────────────
  // Register
  // ──────────────────────────────────────────────

  /// Register user baru.
  /// Return null jika berhasil, atau pesan error jika gagal.
  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (username.trim().isEmpty) return 'Username tidak boleh kosong';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid';
    }
    if (password.length < 6) return 'Password minimal 6 karakter';

    final db = await _db;

    final existingUser = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (existingUser.isNotEmpty) return 'Username sudah digunakan';

    final existingEmail = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (existingEmail.isNotEmpty) return 'Email sudah digunakan';

    final newUser = UserModel(
      username: username.trim(),
      email: email.trim().toLowerCase(),
      encryptedPassword: EncryptionHelper.encryptPassword(password),
    );
    await db.insert('users', newUser.toMap());
    return null;
  }

  // ──────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────

  /// Login dengan username + password.
  /// Return UserModel jika berhasil, null jika gagal.
  Future<UserModel?> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) return null;

    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (rows.isEmpty) return null;

    final user = UserModel.fromMap(rows.first);
    final decrypted = EncryptionHelper.decryptPassword(user.encryptedPassword);
    return decrypted == password ? user : null;
  }

  // ──────────────────────────────────────────────
  // Lookup by username (untuk login biometrik)
  // ──────────────────────────────────────────────

  Future<UserModel?> getUserByUsername(String username) async {
    if (username.trim().isEmpty) return null;

    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }
}
