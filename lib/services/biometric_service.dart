// =============================================================================
// biometric_service.dart
// Service autentikasi biometrik menggunakan local_auth.
//
// Data sidik jari (label & metadata) disimpan di tabel SQLite 'fingerprints'
// yang terhubung ke userId sehingga setiap user punya record sidik jari sendiri.
// =============================================================================

import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database_helper.dart';
import '../models/fingerprint_model.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  // ──────────────────────────────────────────────
  // Hardware checks
  // ──────────────────────────────────────────────

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isFingerprintAvailable() async {
    final available = await getAvailableBiometrics();
    return available.contains(BiometricType.fingerprint) ||
        available.contains(BiometricType.strong);
  }

  // ──────────────────────────────────────────────
  // Autentikasi biometrik hardware
  // ──────────────────────────────────────────────

  Future<BiometricResult> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return BiometricResult(
          success: false,
          error: BiometricError.notSupported,
          message: 'Perangkat tidak mendukung autentikasi biometrik.',
        );
      }

      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return BiometricResult(
          success: false,
          error: BiometricError.notEnrolled,
          message:
              'Tidak ada biometrik yang terdaftar. Silakan daftarkan sidik jari di pengaturan perangkat.',
        );
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return BiometricResult(
        success: didAuthenticate,
        error: didAuthenticate ? null : BiometricError.failed,
        message: didAuthenticate
            ? 'Autentikasi berhasil.'
            : 'Autentikasi dibatalkan atau gagal.',
      );
    } on Exception catch (e) {
      return BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ──────────────────────────────────────────────
  // CRUD data sidik jari per user
  // ──────────────────────────────────────────────

  /// Tambah record sidik jari untuk user tertentu.
  Future<void> tambahFingerprint(FingerprintModel fp) async {
    final db = await _db;
    await db.insert('fingerprints', fp.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Ambil semua sidik jari milik [userId].
  Future<List<FingerprintModel>> getFingerprintsByUser(int userId) async {
    final db = await _db;
    final rows = await db.query(
      'fingerprints',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'addedAt DESC',
    );
    return rows.map(FingerprintModel.fromMap).toList();
  }

  /// Hapus sidik jari berdasarkan id-nya.
  Future<void> hapusFingerprint(int id) async {
    final db = await _db;
    await db.delete('fingerprints', where: 'id = ?', whereArgs: [id]);
  }

  /// Cek apakah user sudah punya minimal 1 sidik jari terdaftar.
  Future<bool> hasFingerprint(int userId) async {
    final list = await getFingerprintsByUser(userId);
    return list.isNotEmpty;
  }
}

enum BiometricError { notSupported, notEnrolled, failed, unknown }

class BiometricResult {
  final bool success;
  final BiometricError? error;
  final String message;

  const BiometricResult({
    required this.success,
    this.error,
    required this.message,
  });
}
