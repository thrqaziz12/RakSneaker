// =============================================================================
// home_screen.dart
// Halaman utama setelah user berhasil login ke aplikasi RakSneaker.
//
// Fitur:
//   - Menampilkan sapaan dengan nama username yang sedang login
//   - Tombol logout untuk kembali ke halaman LoginScreen
//
// Tema Warna (Sneaker Collection Theme):
//   - Primary Accent : #FF6B35 (Oranye Sneaker)
//   - Background     : #0F0E0C (Hitam Hangat)
//   - Surface/AppBar : #1C1A16 (Abu Karbon Hangat)
// =============================================================================

import 'package:flutter/material.dart';
import 'login_screen.dart';

const kPrimaryColor = Color(0xFFFF6B35);
const kBgDark = Color(0xFF0F0E0C);
const kSurfaceDark = Color(0xFF1C1A16);

/// Halaman beranda yang ditampilkan setelah login berhasil.
class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        // AppBar dengan warna karbon hangat.
        backgroundColor: kSurfaceDark,
        title: Row(
          children: [
            // Ikon kecil sneaker di samping nama app.
            const Icon(
              Icons.directions_run_rounded,
              color: kPrimaryColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'RakSneaker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar dengan aksen oranye sneaker.
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                // Latar lingkaran oranye transparan.
                color: kPrimaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                // Ikon dengan aksen oranye.
                color: kPrimaryColor,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selamat datang,',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Siap mengelola koleksi sneakermu 👟',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
