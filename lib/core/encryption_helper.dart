import 'package:encrypt/encrypt.dart' as enc;

class EncryptionHelper {
  // Key AES 256-bit (32 karakter)
  static const String _rawKey = 'RakSneaker2024SecureKey32Chars!!';
  // IV 128-bit (16 karakter)
  static const String _rawIV = 'RakSneakerIV16!!';

  static final enc.Key _key = enc.Key.fromUtf8(_rawKey);
  static final enc.IV _iv = enc.IV.fromUtf8(_rawIV);
  static final enc.Encrypter _encrypter = enc.Encrypter(
    enc.AES(_key, mode: enc.AESMode.cbc),
  );

  /// Mengenkripsi password plaintext menjadi string terenkripsi (base64)
  static String encryptPassword(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Mendekripsi string terenkripsi (base64) kembali ke plaintext
  static String decryptPassword(String encryptedBase64) {
    final decrypted = _encrypter.decrypt64(encryptedBase64, iv: _iv);
    return decrypted;
  }
}
