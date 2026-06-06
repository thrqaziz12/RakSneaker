// =============================================================================
// home_screen.dart
// Halaman utama setelah user berhasil login ke aplikasi RakSneaker.
//
// Fitur:
//   - Menampilkan sapaan dengan nama username yang sedang login
//   - Tombol logout untuk kembali ke halaman LoginScreen
// =============================================================================

import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Halaman beranda yang ditampilkan setelah login berhasil.
///
/// Menerima [username] dari LoginScreen untuk ditampilkan sebagai sapaan.
class HomeScreen extends StatelessWidget {
  /// Username dari user yang sedang login.
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Warna latar gelap utama.
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E30),
        title: const Text(
          'RakSneaker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol logout di pojok kanan AppBar.
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: () {
              // Hapus semua stack navigasi dan kembali ke LoginScreen.
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
            // Avatar placeholder berbentuk lingkaran dengan ikon person.
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                // Latar lingkaran ungu transparan 15%.
                // withValues(alpha:) menggantikan withOpacity() yang deprecated.
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF6C63FF),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Teks sapaan: label statis.
            Text(
              'Selamat datang,',
              style: TextStyle(
                // withValues(alpha:) menggantikan withOpacity() yang deprecated.
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),

            // Nama username yang sedang login.
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Keterangan status login.
            Text(
              'Kamu berhasil login ke RakSneaker',
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
