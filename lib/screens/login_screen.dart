// =============================================================================
// login_screen.dart
// Halaman Login untuk aplikasi RakSneaker.
//
// Fitur:
//   - Input username dan password
//   - Validasi form sebelum submit
//   - Autentikasi menggunakan AuthService (Hive + AES)
//   - Animasi fade & slide saat halaman pertama dibuka
//   - Toggle visibility password
//   - Navigasi ke RegisterScreen dan HomeScreen
//
// Tema Warna (Light Mode — Sneaker Collection Theme):
//   - Primary Accent : #FF6B35 (Oranye Sneaker)
//   - Background     : #FFF8F5 (Putih Hangat)
//   - Surface        : #FFFFFF (Putih)
//   - Surface Offset : #FFF0E8 (Krem Oranye Muda)
//   - Text Utama     : #1A1A1A (Hampir Hitam)
//   - Text Muted     : #6B6B6B (Abu)
//   - Error          : #D92B4B (Merah)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

// ---------------------------------------------------------------------------
// Konstanta Warna — Light Sneaker Theme
// ---------------------------------------------------------------------------

/// Aksen utama: oranye-merah khas kultur sneaker/streetwear.
const kPrimaryColor = Color(0xFFFF6B35);

/// Varian lebih gelap dari aksen utama (hover/active).
const kPrimaryDark = Color(0xFFD94F1A);

/// Latar belakang utama: putih hangat.
const kBgLight = Color(0xFFFFF8F5);

/// Permukaan card / container: putih bersih.
const kSurfaceLight = Color(0xFFFFFFFF);

/// Permukaan aksen ringan: krem oranye muda.
const kSurfaceAccent = Color(0xFFFFF0E8);

/// Teks utama: hampir hitam.
const kTextPrimary = Color(0xFF1A1A1A);

/// Teks sekunder: abu.
const kTextMuted = Color(0xFF6B6B6B);

/// Teks tersier / placeholder.
const kTextFaint = Color(0xFFB0B0B0);

/// Warna border input.
const kBorderColor = Color(0xFFE8E0DB);

/// Warna teks merah untuk error.
const kErrorColor = Color(0xFFD92B4B);

/// Halaman login yang menampilkan form username dan password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // --- Form & Controller ---
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  // --- State ---
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // --- Animasi ---
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

    await Future.delayed(const Duration(milliseconds: 600));

    final user = _authService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(username: user.username)),
      );
    } else {
      setState(() {
        _errorMessage = 'Username atau password salah';
      });
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

                      // -------------------------------------------------------
                      // Logo & Judul Aplikasi
                      // -------------------------------------------------------
                      Center(
                        child: Column(
                          children: [
                            // Lingkaran latar aksen krem supaya logo terlihat jelas.
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                // Gradient oranye terang → oranye gelap.
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
                                    // Efek bayangan oranye lembut (light mode).
                                    color: kPrimaryColor.withValues(
                                      alpha: 0.30,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                // Menggunakan Icons.sports bawaan Flutter sebagai
                                // fallback yang selalu render. Ganti dengan
                                // MdiIcons.shoeSneaker jika font MDI sudah
                                // terdaftar dengan benar.
                                MdiIcons.shoeSneaker,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Nama aplikasi — teks gelap supaya kontras di bg terang.
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
                            // Tagline.
                            const Text(
                              'Koleksi sneakermu, tertata rapi',
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Label halaman.
                            const Text(
                              'Masuk ke akun kamu',
                              style: TextStyle(fontSize: 14, color: kTextFaint),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // -------------------------------------------------------
                      // Form Login
                      // -------------------------------------------------------
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

                      // -------------------------------------------------------
                      // Pesan Error
                      // -------------------------------------------------------
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
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: kErrorColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // -------------------------------------------------------
                      // Tombol Login
                      // -------------------------------------------------------
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

                      const Spacer(),

                      // -------------------------------------------------------
                      // Link Register
                      // -------------------------------------------------------
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
            // Surface card putih bersih.
            fillColor: kSurfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            // Border fokus: oranye sneaker.
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
