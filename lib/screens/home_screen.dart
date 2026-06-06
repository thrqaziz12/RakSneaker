// =============================================================================
// home_screen.dart — RakSneaker (Light Theme)
// =============================================================================

import 'package:flutter/material.dart';
import 'login_screen.dart';

const kPrimary    = Color(0xFFFF6B35);
const kBg         = Color(0xFFFAF9F7);
const kSurface    = Color(0xFFFFFFFF);
const kSurfaceOff = Color(0xFFF5F4F0);
const kTextDark   = Color(0xFF1A1714);
const kTextMid    = Color(0xFF6B6560);
const kBorder     = Color(0xFFE8E5E1);

class HomeScreen extends StatelessWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // Garis bawah tipis sebagai pemisah AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
        title: Row(
          children: [
            // Ikon oranye kecil di samping nama app
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: kPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'RakSneaker',
              style: TextStyle(
                color: kTextDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kTextMid),
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
            // Avatar dengan ring oranye
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.30),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: kPrimary,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat datang,',
              style: TextStyle(color: kTextMid, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              username,
              style: const TextStyle(
                color: kTextDark,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: kPrimary.withValues(alpha: 0.20)),
              ),
              child: const Text(
                '👟  Siap mengelola koleksi sneakermu',
                style: TextStyle(
                    color: kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
