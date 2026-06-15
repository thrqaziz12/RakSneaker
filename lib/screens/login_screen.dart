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
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'register_screen.dart';
import 'main_screen.dart';

const kPrimaryColor = Color(0xFFFF6B35);
const kPrimaryDark  = Color(0xFFD94F1A);
const kBgLight      = Color(0xFFFFF8F5);
const kSurfaceLight = Color(0xFFFFFFFF);
const kSurfaceAccent = Color(0xFFFFF0E8);
const kTextPrimary  = Color(0xFF1A1A1A);
const kTextMuted    = Color(0xFF6B6B6B);
const kTextFaint    = Color(0xFFB0B0B0);
const kBorderColor  = Color(0xFFE8E0DB);
const kErrorColor   = Color(0xFFD92B4B);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isBiometricAvailable = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
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
    final enrolled = await _biometricService.canCheckBiometrics();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // FIX v4.3: Future.delayed(600ms) dihapus — tidak memberikan manfaat
    // dan hanya menambah latensi yang tidak perlu sebelum request login.

    // FIX v4.1: tambah await — login() adalah async Future<UserModel?>
    final user = await _authService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    // Guard: pastikan widget masih terpasang setelah await
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (user != null) {
      // Simpan username agar bisa digunakan untuk login biometrik berikutnya
      await _authService.saveLastLoggedInUsername(user.username);

      // Guard setelah await kedua sebelum menggunakan context
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            username: user.username,
            userId: user.id ?? 0,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Username atau password salah';
      });
    }
  }

  /// Login menggunakan biometrik (fingerprint) — tidak perlu input username.
  /// Username diambil otomatis dari riwayat login terakhir yang tersimpan.
  Future<void> _handleBiometricLogin() async {
    // FIX v4.1: tambah await — getLastLoggedInUsername() adalah async Future<String?>
    final savedUsername = await _authService.getLastLoggedInUsername();

    if (savedUsername == null || savedUsername.isEmpty) {
      setState(() {
        _errorMessage =
            'Silakan login dengan username & password terlebih dahulu, '
            'lalu Anda bisa menggunakan sidik jari untuk login berikutnya.';
      });
      return;
    }

    setState(() {
      _isBiometricLoading = true;
      _errorMessage = null;
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              username: user.username,
              userId: user.id ?? 0,
            ),
          ),
        );
      } else {
        // Akun tidak ditemukan (misalnya sudah dihapus)
        setState(() {
          _errorMessage =
              'Akun tidak ditemukan. Silakan login dengan username & password.';
        });
      }
    } else {
      if (result.error == BiometricError.notEnrolled) {
        setState(() {
          _errorMessage =
              'Tidak ada sidik jari terdaftar di perangkat. '
              'Daftarkan dulu di Pengaturan perangkat.';
        });
      } else if (result.error == BiometricError.notSupported) {
        setState(() {
          _errorMessage = 'Perangkat tidak mendukung autentikasi biometrik.';
        });
      } else {
        setState(() {
          _errorMessage = 'Autentikasi biometrik dibatalkan atau gagal.';
        });
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

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _usernameController,
                              label: 'Username',
                              hint: 'Masukkan username',
                              icon: Icons.person_outline_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }
                                return null;
                              },
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
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: kErrorColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kErrorColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: kErrorColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: kErrorColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

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
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
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
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kErrorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kErrorColor, width: 1.5),
            ),
            errorStyle: const TextStyle(color: kErrorColor),
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
