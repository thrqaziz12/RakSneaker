// =============================================================================
// biometric_service.dart
// Service untuk autentikasi biometrik nyata menggunakan local_auth.
//
// Fitur:
//   - Cek ketersediaan sensor biometrik di perangkat
//   - Cek jenis biometrik yang tersedia (fingerprint, face, iris)
//   - Autentikasi biometrik dengan pesan yang dapat dikustomisasi
//   - Handle error gracefully
// =============================================================================

import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Cek apakah perangkat mendukung biometrik
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Cek apakah ada biometrik yang sudah terdaftar di perangkat
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Ambil daftar jenis biometrik yang tersedia
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Cek apakah sensor fingerprint tersedia
  Future<bool> isFingerprintAvailable() async {
    final available = await getAvailableBiometrics();
    return available.contains(BiometricType.fingerprint) ||
        available.contains(BiometricType.strong);
  }

  /// Lakukan autentikasi biometrik
  /// [reason] : pesan yang ditampilkan kepada pengguna
  /// Returns true jika autentikasi berhasil
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
        message: didAuthenticate ? 'Autentikasi berhasil.' : 'Autentikasi dibatalkan atau gagal.',
      );
    } on Exception catch (e) {
      return BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}

enum BiometricError {
  notSupported,
  notEnrolled,
  failed,
  unknown,
}

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
