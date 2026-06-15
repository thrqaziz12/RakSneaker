// =============================================================================
// session_service.dart
// Mengelola sesi login user menggunakan SharedPreferences.
//
// Sesi disimpan saat login berhasil dan dihapus saat logout.
// Saat app dibuka, sesi dicek — jika aktif, user langsung masuk ke MainScreen
// tanpa perlu login ulang.
//
// Keys yang digunakan:
//   - 'session_is_logged_in'  : bool
//   - 'session_username'      : String
//   - 'session_user_id'       : int
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyIsLoggedIn = 'session_is_logged_in';
  static const _keyUsername   = 'session_username';
  static const _keyUserId     = 'session_user_id';

  // ──────────────────────────────────────────────
  // Simpan sesi setelah login berhasil
  // ──────────────────────────────────────────────

  /// Simpan data sesi user yang berhasil login.
  Future<void> saveSession({
    required String username,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setInt(_keyUserId, userId);
  }

  // ──────────────────────────────────────────────
  // Baca sesi aktif
  // ──────────────────────────────────────────────

  /// Cek apakah ada sesi login yang aktif.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Ambil username dari sesi aktif.
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  /// Ambil userId dari sesi aktif.
  Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId) ?? 0;
  }

  // ──────────────────────────────────────────────
  // Hapus sesi saat logout
  // ──────────────────────────────────────────────

  /// Hapus semua data sesi (dipanggil saat logout).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserId);
  }
}
