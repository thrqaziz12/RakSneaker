// =============================================================================
// register_screen.dart
// Halaman Registrasi untuk aplikasi RakSneaker.
//
// Fitur:
//   - Input username, email, password, dan konfirmasi password
//   - Validasi form lengkap (format email, panjang password, kecocokan password)
//   - Registrasi menggunakan AuthService (simpan ke Hive + enkripsi AES)
//   - Animasi fade & slide saat halaman pertama dibuka
//   - Dialog sukses sebelum redirect ke halaman Login
//
// Tema Warna (Light Mode — Sneaker Collection Theme):
//   - Primary Accent : #FF6B35 (Oranye Sneaker)
//   - Background     : #FFF8F5 (Putih Hangat)
//   - Surface        : #FFFFFF (Putih)
//   - Surface Offset : #FFF0E8 (Krem Oranye Muda)
//   - Text Utama     : #1A1A1A (Hampir Hitam)
//   - Text Muted     : #6B6B6B (Abu)
//   - Success        : #22C55E (Hijau)
//   - Error          : #D92B4B (Merah)
// =============================================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Konstanta Warna — Light Sneaker Theme (sesuai login_screen.dart)
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

/// Warna hijau untuk sukses.
const kSuccessColor = Color(0xFF22C55E);

/// Halaman registrasi untuk membuat akun baru.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error == null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          // Dialog surface menggunakan putih bersih — sesuai light mode.
          backgroundColor: kSurfaceLight,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: kSuccessColor, size: 24),
              SizedBox(width: 8),
              Text(
                'Registrasi Berhasil',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Akun kamu berhasil dibuat. Silakan login untuk mulai mengelola koleksi sneakermu!',
            style: TextStyle(color: kTextMuted, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _errorMessage = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // -------------------------------------------------------
                  // Tombol Back
                  // -------------------------------------------------------
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // Tombol back menggunakan surface krem oranye muda.
                        color: kSurfaceAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: kBorderColor,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: kTextMuted,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // -------------------------------------------------------
                  // Judul & Sub-judul
                  // -------------------------------------------------------
                  const Text(
                    'Buat Akun Baru',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      // Teks gelap di background terang — kontras tinggi.
                      color: kTextPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Daftarkan dirimu dan mulai kelola koleksi sneakermu',
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // -------------------------------------------------------
                  // Form Registrasi
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
                            if (val.trim().length < 3) {
                              return 'Username minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'contoh@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Minimal 6 karakter',
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
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (val.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Konfirmasi Password',
                          hint: 'Ulangi password kamu',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: kTextFaint,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (val != _passwordController.text) {
                              return 'Password tidak cocok';
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kErrorColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: kErrorColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: kErrorColor, size: 18),
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

                  // -------------------------------------------------------
                  // Tombol Daftar
                  // -------------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: kPrimaryColor.withValues(alpha: 0.30),
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
                              'Daftar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // -------------------------------------------------------
                  // Link kembali ke Login
                  // -------------------------------------------------------
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Sudah punya akun? ',
                          style: TextStyle(
                            color: kTextMuted,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Masuk di sini',
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
                  const SizedBox(height: 32),
                ],
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            // Label teks abu gelap — terbaca di light mode.
            color: kTextMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          // Teks input gelap di background putih.
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextFaint),
            prefixIcon: Icon(icon, color: kTextFaint, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            // Surface putih bersih untuk input field.
            fillColor: kSurfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor, width: 1),
            ),
            // Border fokus oranye sneaker.
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
