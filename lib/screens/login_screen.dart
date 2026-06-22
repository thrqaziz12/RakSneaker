// =============================================================================
// login_screen.dart
// Halaman Login untuk aplikasi RakSneaker.
//
// Perubahan v4:
//   - Login biometrik tidak lagi memerlukan input username manual
//   - Username diambil otomatis dari riwayat login terakhir (Hive 'settings')
//   - Saat login password berhasil, username disimpan ke storage
//   - Pesan error yang jelas jika belum pernah login sebelumnya
//
// Fix v4.1:
//   - Tambah await pada _authService.getLastLoggedInUsername() [async Future<String?>]
//   - Tambah await pada _authService.login() [async Future<UserModel?>]
//
// Fix v4.2:
//   - Teruskan user.id ke MainScreen sebagai parameter userId
//
// Fix v4.3:
//   - Hapus Future.delayed(600ms) yang tidak perlu di _handleLogin()
//
// v5 — Session:
//   - Simpan sesi via SessionService setelah login password maupun biometrik
//
// v6 — Pop-up Warning:
//   - Validasi form menggunakan dialog pop-up di tengah layar
//   - Tidak ada lagi error text inline di bawah field
//
// v7 — Fix login biometrik saat sidik jari dinonaktifkan:
//   - Tambah pengecekan apakah user memiliki sidik jari aktif di SQLite
//     sebelum memproses login biometrik
//   - Jika fitur sidik jari dinonaktifkan (tidak ada record di tabel
//     'fingerprints'), tampilkan dialog peringatan dan batalkan login
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../core/database_helper.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/session_service.dart';
import 'register_screen.dart';
import 'main_screen.dart';

const kPrimaryColor  = Color(0xFFFF6B35);
const kPrimaryDark   = Color(0xFFD94F1A);
const kBgLight       = Color(0xFFFFF8F5);
const kSurfaceLight  = Color(0xFFFFFFFF);
const kSurfaceAccent = Color(0xFFFFF0E8);
const kTextPrimary   = Color(0xFF1A1A1A);
const kTextMuted     = Color(0xFF6B6B6B);
const kTextFaint     = Color(0xFFB0B0B0);
const kBorderColor   = Color(0xFFE8E0DB);
const kErrorColor    = Color(0xFFD92B4B);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService        = AuthService();
  final _biometricService   = BiometricService();
  final _sessionService     = SessionService();
  final _dbHelper           = DatabaseHelper();

  bool    _isLoading          = false;
  bool    _isBiometricLoading = false;
  bool    _obscurePassword    = true;
  String? _errorMessage;
  bool    _isBiometricAvailable = false;

  late AnimationController _animController;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation  = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final supported = await _biometricService.isDeviceSupported();
    final enrolled  = await _biometricService.canCheckBiometrics();
    if (mounted) {
      setState(() => _isBiometricAvailable = supported && enrolled);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Cek apakah user telah mengaktifkan sidik jari
  //  (ada >= 1 record di tabel 'fingerprints' SQLite)
  // ─────────────────────────────────────────────
  Future<bool> _isFingerprintEnabledForUser(String username) async {
    final user = await _authService.getUserByUsername(username);
    if (user == null || user.id == null) return false;

    final db = await _dbHelper.database;
    final rows = await db.query(
      'fingerprints',
      where: 'userId = ?',
      whereArgs: [user.id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  //  Pop-up dialog peringatan di tengah layar
  // ─────────────────────────────────────────────
  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kSurfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon peringatan
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: kErrorColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: kErrorColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // Judul
              const Text(
                'Perhatian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              // Pesan
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: kTextMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Tombol OK
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Validasi manual (tanpa Form + validator)
  // ─────────────────────────────────────────────
  bool _validateInputs() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showWarningDialog('Username tidak boleh kosong.\nSilakan masukkan username kamu.');
      return false;
    }
    if (password.isEmpty) {
      _showWarningDialog('Password tidak boleh kosong.\nSilakan masukkan password kamu.');
      return false;
    }
    return true;
  }

  Future<void> _handleLogin() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    final user = await _authService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      // Simpan username untuk login biometrik berikutnya
      await _authService.saveLastLoggedInUsername(user.username);

      // Simpan sesi agar tidak perlu login ulang saat buka app
      await _sessionService.saveSession(
        username: user.username,
        userId:   user.id ?? 0,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            username: user.username,
            userId:   user.id ?? 0,
          ),
        ),
      );
    } else {
      // Username/password salah — tampilkan pop-up
      _showWarningDialog('Username atau password yang kamu masukkan salah.\nSilakan coba lagi.');
    }
  }

  /// Login menggunakan biometrik (fingerprint) — tidak perlu input username.
  /// Username diambil otomatis dari riwayat login terakhir yang tersimpan.
  ///
  /// PERBAIKAN v7: Sebelum memproses autentikasi biometrik, cek terlebih
  /// dahulu apakah user sudah mengaktifkan fitur sidik jari (ada record
  /// di tabel 'fingerprints' SQLite). Jika fitur dinonaktifkan, tampilkan
  /// dialog peringatan dan batalkan proses login biometrik.
  Future<void> _handleBiometricLogin() async {
    final savedUsername = await _authService.getLastLoggedInUsername();

    if (savedUsername == null || savedUsername.isEmpty) {
      _showWarningDialog(
        'Silakan login dengan username & password terlebih dahulu, '
        'lalu Anda bisa menggunakan sidik jari untuk login berikutnya.',
      );
      return;
    }

    // ── PERBAIKAN: Cek apakah fitur sidik jari diaktifkan untuk user ini ──
    final fingerprintEnabled = await _isFingerprintEnabledForUser(savedUsername);
    if (!fingerprintEnabled) {
      _showWarningDialog(
        'Fitur sidik jari belum diaktifkan untuk akun "$savedUsername".\n\n'
        'Aktifkan terlebih dahulu melalui:\nProfil → Sidik Jari → Aktifkan toggle.',
      );
      return;
    }
    // ──────────────────────────────────────────────────────────────────────

    setState(() {
      _isBiometricLoading = true;
      _errorMessage       = null;
    });

    final result = await _biometricService.authenticate(
      reason: 'Verifikasi sidik jari untuk masuk ke RakSneaker',
    );

    if (!mounted) return;
    setState(() => _isBiometricLoading = false);

    if (result.success) {
      final user = await _authService.getUserByUsername(savedUsername);
      if (!mounted) return;
      if (user != null) {
        // Simpan sesi untuk login biometrik
        await _sessionService.saveSession(
          username: user.username,
          userId:   user.id ?? 0,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              username: user.username,
              userId:   user.id ?? 0,
            ),
          ),
        );
      } else {
        _showWarningDialog(
          'Akun tidak ditemukan.\nSilakan login dengan username & password.',
        );
      }
    } else {
      if (result.error == BiometricError.notEnrolled) {
        _showWarningDialog(
          'Tidak ada sidik jari terdaftar di perangkat.\n'
          'Daftarkan dulu di Pengaturan perangkat.',
        );
      } else if (result.error == BiometricError.notSupported) {
        _showWarningDialog('Perangkat tidak mendukung autentikasi biometrik.');
      } else {
        _showWarningDialog('Autentikasi biometrik dibatalkan atau gagal.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height:
                size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8C5A),
                                    Color(0xFFFF6B35),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryColor.withValues(alpha: 0.30),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                MdiIcons.shoeSneaker,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'RakSneaker',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Koleksi sneakermu, tertata rapi',
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Masuk ke akun kamu',
                              style: TextStyle(fontSize: 14, color: kTextFaint),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      Column(
                        children: [
                          _buildTextField(
                            controller: _usernameController,
                            label: 'Username',
                            hint: 'Masukkan username',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Masukkan password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: kTextFaint,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Tombol Login dengan password
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            shadowColor: kPrimaryColor.withValues(alpha: 0.35),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      // Tombol Login Biometrik (hanya tampil jika tersedia)
                      if (_isBiometricAvailable) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: kBorderColor,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'atau',
                                style: TextStyle(
                                  color: kTextFaint,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: kBorderColor,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isBiometricLoading
                                    ? null
                                    : _handleBiometricLogin,
                            icon: _isBiometricLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kPrimaryColor,
                                    ),
                                  )
                                : const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 22,
                                    color: kPrimaryColor,
                                  ),
                            label: Text(
                              _isBiometricLoading
                                  ? 'Memverifikasi…'
                                  : 'Masuk dengan Sidik Jari',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: kPrimaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: kPrimaryColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),

                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(
                                  color: kTextMuted,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Daftar sekarang',
                                    style: TextStyle(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextFaint),
            prefixIcon: Icon(icon, color: kTextMuted, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: kSurfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
