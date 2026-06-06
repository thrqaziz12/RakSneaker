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
// =============================================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Halaman registrasi untuk membuat akun baru.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // --- Form & Controller ---
  /// Key global untuk mengontrol validasi form.
  final _formKey = GlobalKey<FormState>();

  /// Controller untuk field input username.
  final _usernameController = TextEditingController();

  /// Controller untuk field input email.
  final _emailController = TextEditingController();

  /// Controller untuk field input password.
  final _passwordController = TextEditingController();

  /// Controller untuk field konfirmasi password.
  final _confirmPasswordController = TextEditingController();

  /// Service autentikasi yang menangani logika registrasi.
  final _authService = AuthService();

  // --- State ---
  /// Menandakan proses registrasi sedang berjalan.
  bool _isLoading = false;

  /// Mengontrol visibility karakter pada field password.
  bool _obscurePassword = true;

  /// Mengontrol visibility karakter pada field konfirmasi password.
  bool _obscureConfirm = true;

  /// Pesan error dari server/service yang ditampilkan di bawah form.
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Menangani proses registrasi saat tombol "Daftar" ditekan.
  ///
  /// Alur:
  /// 1. Validasi form input (client-side).
  /// 2. Tampilkan loading indicator.
  /// 3. Panggil [AuthService.register] untuk menyimpan user baru ke Hive.
  /// 4. Jika berhasil → tampilkan dialog sukses → kembali ke [LoginScreen].
  /// 5. Jika gagal → tampilkan pesan error dari service.
  Future<void> _handleRegister() async {
    // Batalkan jika form tidak valid (validasi client-side).
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Panggil AuthService; mengembalikan null jika berhasil,
    // atau String pesan error jika gagal.
    final error = await _authService.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    // Pastikan widget masih mounted sebelum lanjut.
    if (!mounted) return;

    if (error == null) {
      // Registrasi berhasil: tampilkan dialog konfirmasi.
      await showDialog(
        context: context,
        barrierDismissible: false, // User harus tekan OK untuk menutup.
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E30),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF4ADE80), size: 24),
              SizedBox(width: 8),
              Text('Registrasi Berhasil',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Akun kamu berhasil dibuat. Silakan login untuk melanjutkan.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFF6C63FF), fontSize: 15)),
            ),
          ],
        ),
      );
      // Setelah dialog ditutup, kembali ke halaman Login.
      if (mounted) Navigator.pop(context);
    } else {
      // Registrasi gagal: tampilkan pesan error dari service.
      setState(() => _errorMessage = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Warna latar gelap utama.
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
                        color: const Color(0xFF1E1E30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // -------------------------------------------------------
                  // Judul Halaman
                  // -------------------------------------------------------
                  const Text(
                    'Buat Akun Baru',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Daftarkan dirimu untuk mulai belanja sneaker',
                    style: TextStyle(
                      fontSize: 14,
                      // withValues(alpha:) menggantikan withOpacity() deprecated.
                      color: Colors.white.withValues(alpha: 0.5),
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
                        // Field username (min. 3 karakter).
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

                        // Field email dengan validasi format dasar.
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

                        // Field password (min. 6 karakter).
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
                            if (val.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Field konfirmasi password (harus sama dengan password).
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
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            // Pastikan cocok dengan password utama.
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
                  // Pesan Error (hanya tampil jika registrasi gagal)
                  // -------------------------------------------------------
                  if (_errorMessage != null) ...
                    [
                      const SizedBox(height: 16),
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
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFFF4D6D),
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
                      // Nonaktifkan tombol saat loading.
                      onPressed: _isLoading ? null : _handleRegister,
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
                  // Link kembali ke halaman Login
                  // -------------------------------------------------------
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Masuk di sini',
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
                  const SizedBox(height: 32),
                ],
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
  /// - [controller]    : TextEditingController untuk membaca nilai input.
  /// - [label]         : Teks label di atas field.
  /// - [hint]          : Teks placeholder di dalam field.
  /// - [icon]          : Ikon prefix di sisi kiri field.
  /// - [obscureText]   : Sembunyikan karakter (untuk password). Default: false.
  /// - [suffixIcon]    : Widget opsional di sisi kanan (misal: tombol eye).
  /// - [keyboardType]  : Jenis keyboard (misal: emailAddress untuk field email).
  /// - [validator]     : Fungsi validasi yang dijalankan saat form disubmit.
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
          keyboardType: keyboardType,
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
