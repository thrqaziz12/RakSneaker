// =============================================================================
// home_screen.dart
// Halaman utama setelah user berhasil login ke aplikasi RakSneaker.
//
// Fitur:
//   - Menampilkan sapaan dengan nama username yang sedang login
//   - Tombol logout untuk kembali ke halaman LoginScreen
//
// Tema Warna (Light Mode — Sneaker Collection Theme):
//   - Primary Accent : #FF6B35 (Oranye Sneaker)
//   - Background     : #FFF8F5 (Putih Hangat)
//   - Surface/AppBar : #FFFFFF (Putih)
//   - Text Utama     : #1A1A1A (Hampir Hitam)
//   - Text Muted     : #6B6B6B (Abu)
// =============================================================================

import 'package:flutter/material.dart';
import 'login_screen.dart';

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

/// Warna border.
const kBorderColor = Color(0xFFE8E0DB);

/// Halaman beranda yang ditampilkan setelah login berhasil.
class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        // AppBar dengan warna surface putih bersih — konsisten dengan login.
        backgroundColor: kSurfaceLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // Garis bawah halus sebagai separator.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: kBorderColor,
          ),
        ),
        title: Row(
          children: [
            // Logo container oranye kecil di AppBar.
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C5A), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'RakSneaker',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // Tombol logout dengan warna muted — tidak mencolok di light mode.
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kTextMuted),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar dengan latar aksen oranye muda — selaras dengan tema login.
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kSurfaceAccent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimaryColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: kPrimaryColor,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat datang,',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              username,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Siap mengelola koleksi sneakermu 👟',
              style: TextStyle(
                color: kTextFaint,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            // Kartu dekoratif — permukaan aksen oranye muda.
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: kSurfaceAccent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kPrimaryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Login berhasil!',
                    style: TextStyle(
                      color: kPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
