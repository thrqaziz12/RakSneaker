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
// =============================================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

/// Halaman login yang menampilkan form username dan password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // --- Form & Controller ---
  /// Key global untuk mengontrol validasi form.
  final _formKey = GlobalKey<FormState>();

  /// Controller untuk field input username.
  final _usernameController = TextEditingController();

  /// Controller untuk field input password.
  final _passwordController = TextEditingController();

  /// Service autentikasi yang menangani logika login.
  final _authService = AuthService();

  // --- State ---
  /// Menandakan proses login sedang berjalan (tampilkan loading indicator).
  bool _isLoading = false;

  /// Mengontrol visibility karakter pada field password.
  bool _obscurePassword = true;

  /// Pesan error yang ditampilkan jika login gagal.
  String? _errorMessage;

  // --- Animasi ---
  /// Controller untuk mengelola animasi masuk halaman.
  late AnimationController _animController;

  /// Animasi opacity (fade in) saat halaman muncul.
  late Animation<double> _fadeAnimation;

  /// Animasi posisi (slide up) saat halaman muncul.
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Inisialisasi AnimationController dengan durasi 800ms.
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Fade in dari transparan ke penuh.
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    // Slide dari bawah ke posisi normal.
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Mulai animasi saat widget pertama kali dibuat.
    _animController.forward();
  }

  @override
  void dispose() {
    // Bebaskan semua resource controller saat widget dihapus dari tree.
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Menangani proses login saat tombol "Masuk" ditekan.
  ///
  /// Alur:
  /// 1. Validasi form input.
  /// 2. Tampilkan loading indicator.
  /// 3. Panggil [AuthService.login] dengan username & password.
  /// 4. Jika berhasil → navigasi ke [HomeScreen].
  /// 5. Jika gagal → tampilkan pesan error.
  Future<void> _handleLogin() async {
    // Batalkan jika form tidak valid.
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulasi jeda kecil untuk UX yang lebih natural.
    await Future.delayed(const Duration(milliseconds: 600));

    // Coba autentikasi user; mengembalikan UserModel jika berhasil.
    final user = _authService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    // Pastikan widget masih mounted sebelum melakukan navigasi.
    if (!mounted) return;

    if (user != null) {
      // Login berhasil: pindah ke HomeScreen dan hapus LoginScreen dari stack.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(username: user.username),
        ),
      );
    } else {
      // Login gagal: tampilkan pesan error di bawah form.
      setState(() {
        _errorMessage = 'Username atau password salah';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil ukuran layar untuk menghitung tinggi konten agar pas di viewport.
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Warna latar gelap utama.
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            // Tinggi tepat satu layar (dikurangi safe area atas & bawah).
            height: size.height -
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
                            // Ikon toko dengan efek glow ungu.
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    // Efek glow: warna ungu dengan opacity 40%.
                                    // Menggunakan withValues(alpha:) — pengganti
                                    // withOpacity() yang sudah deprecated.
                                    color: const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Nama aplikasi.
                            const Text(
                              'RakSneaker',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Subtitle / tagline halaman login.
                            Text(
                              'Masuk ke akun kamu',
                              style: TextStyle(
                                fontSize: 14,
                                // withValues(alpha:) menggantikan withOpacity()
                                // yang deprecated sejak Flutter 3.27.
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
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
                            // Field username.
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

                            // Field password dengan toggle show/hide.
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
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
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
                      // Pesan Error (hanya tampil jika login gagal)
                      // -------------------------------------------------------
                      if (_errorMessage != null) ...
                        [
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              // Latar merah transparan 12%.
                              color: const Color(0xFFFF4D6D)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                // Border merah transparan 30%.
                                color: const Color(0xFFFF4D6D)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFFF4D6D), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF4D6D),
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
                          // Nonaktifkan tombol saat loading.
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          // Tampilkan spinner saat loading, teks normal jika tidak.
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
                      // Link menuju halaman Register
                      // -------------------------------------------------------
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: RichText(
                              text: TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Daftar sekarang',
                                    style: TextStyle(
                                      color: Color(0xFF6C63FF),
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

  /// Membangun widget TextField yang konsisten dan dapat dikonfigurasi.
  ///
  /// Parameter:
  /// - [controller] : TextEditingController untuk membaca nilai input.
  /// - [label]      : Teks label yang ditampilkan di atas field.
  /// - [hint]       : Teks placeholder di dalam field.
  /// - [icon]       : Ikon prefix di sisi kiri field.
  /// - [obscureText]: Sembunyikan karakter (untuk password). Default: false.
  /// - [suffixIcon] : Widget opsional di sisi kanan field (misal: tombol eye).
  /// - [validator]  : Fungsi validasi yang dijalankan saat form disubmit.
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
        // Label di atas field.
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Input field dengan styling dark theme.
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
            ),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF1E1E30),
            // Border default: tanpa garis.
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            // Border saat field aktif (focused): ungu.
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
            ),
            // Border saat ada error validasi.
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFF4D6D), width: 1),
            ),
            // Border saat ada error dan field masih aktif.
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFF4D6D), width: 1.5),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFF4D6D)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
