// =============================================================================
// profile_screen.dart
// Halaman Profile pada BottomNavigationBar RakSneaker.
//
// Konten:
//   - Info akun user (username, avatar)
//   - Menu tile navigasi ke FingerprintScreen
//   - Section Pesan & Kesan (Teknologi Pemrograman Mobile)
//   - Tombol Logout
//
// Tema: Light Mode Sneaker — Oranye #FF6B35
//
// Fix logout:
//   Menggunakan navigatorKey global dari main.dart agar navigasi logout
//   tidak bergantung pada BuildContext yang bisa sudah tidak valid
//   ketika ProfileScreen berada di dalam IndexedStack.
//
// v5 — Session:
//   Hapus sesi via SessionService saat logout dilakukan.
//
// v6 — Pesan & Kesan:
//   Menambahkan section Pesan & Kesan statis (read-only) dari mahasiswa
//   untuk mata kuliah Teknologi Pemrograman Mobile.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../main.dart' show navigatorKey;
import '../services/session_service.dart';
import 'fingerprint_screen.dart';
import 'login_screen.dart';

const _kPrimary       = Color(0xFFFF6B35);
const _kBg            = Color(0xFFFFF8F5);
const _kSurface       = Color(0xFFFFFFFF);
const _kSurfaceAccent = Color(0xFFFFF0E8);
const _kTextPrimary   = Color(0xFF1A1A1A);
const _kTextMuted     = Color(0xFF6B6B6B);
const _kTextFaint     = Color(0xFFB0B0B0);
const _kBorder        = Color(0xFFE8E0DB);
const _kError         = Color(0xFFD92B4B);

// ---------------------------------------------------------------------------
// Data Pesan & Kesan — READ ONLY, tidak dapat ditambah/edit/hapus
// ---------------------------------------------------------------------------
const _kNamaMahasiswa = 'Muhammad Thoriq Aziz';
const _kNIM           = '123230233';
const _kPesan =
    'Mata kuliah Teknologi Pemrograman Mobile sangat bermanfaat dan memberikan '
    'pengalaman nyata dalam membangun aplikasi mobile menggunakan Flutter. '
    'Semoga ke depannya materi terus diperbarui mengikuti perkembangan teknologi '
    'sehingga mahasiswa semakin siap terjun ke dunia industri.';
const _kKesan =
    'Kesan selama mengikuti mata kuliah ini sangat positif. Proses belajar yang '
    'menyenangkan, tugas-tugas yang menantang, serta bimbingan dosen yang sabar '
    'membuat pemahaman terhadap pengembangan aplikasi mobile menjadi jauh lebih '
    'mendalam. Terima kasih atas ilmu yang telah diberikan!';

class ProfileScreen extends StatelessWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        title: Row(
          children: [
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
              child:
                  Icon(MdiIcons.shoeSneaker, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Profile',
              style: TextStyle(
                color: _kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------------
            // Avatar & Info Akun
            // -------------------------------------------------------------------
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _kSurfaceAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kPrimary.withValues(alpha: 0.30),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _kPrimary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    username,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Akun Aktif',
                    style: TextStyle(color: _kTextMuted, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // -------------------------------------------------------------------
            // Section: Keamanan
            // -------------------------------------------------------------------
            const Text(
              'KEAMANAN',
              style: TextStyle(
                color: _kTextFaint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.fingerprint_rounded,
              iconColor: _kPrimary,
              label: 'Sidik Jari',
              sublabel: 'Kelola autentikasi sidik jari',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FingerprintScreen(username: username),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // -------------------------------------------------------------------
            // Section: Pesan & Kesan (READ ONLY)
            // -------------------------------------------------------------------
            const Text(
              'PESAN & KESAN',
              style: TextStyle(
                color: _kTextFaint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            _PesanKesanCard(),

            const SizedBox(height: 32),

            // -------------------------------------------------------------------
            // Section: Akun
            // -------------------------------------------------------------------
            const Text(
              'AKUN',
              style: TextStyle(
                color: _kTextFaint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.logout_rounded,
              iconColor: _kError,
              label: 'Logout',
              sublabel: 'Keluar dari akun ini',
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style:
              TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Yakin ingin keluar dari akun ini?',
          style: TextStyle(color: _kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: _kTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              // Tutup dialog terlebih dahulu
              Navigator.pop(ctx);

              // Hapus sesi agar app tidak langsung masuk saat dibuka kembali
              await SessionService().clearSession();

              // Gunakan global navigatorKey — dijamin tidak bergantung
              // pada BuildContext yang mungkin sudah tidak valid.
              navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget Pesan & Kesan Card — READ ONLY
// Menampilkan identitas mahasiswa, pesan, dan kesan selama kuliah
// Teknologi Pemrograman Mobile. Tidak ada aksi tambah/edit/hapus.
// ---------------------------------------------------------------------------
class _PesanKesanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header identitas mahasiswa
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kSurfaceAccent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _kPrimary.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: _kPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      _kNamaMahasiswa,
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'NIM: $_kNIM',
                      style: TextStyle(
                        color: _kTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge read-only
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kSurfaceAccent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kPrimary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'Read Only',
                  style: TextStyle(
                    color: _kPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: _kBorder, height: 1),
          const SizedBox(height: 16),

          // Mata kuliah
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kSurfaceAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Mata Kuliah: Teknologi Pemrograman Mobile',
              style: TextStyle(
                color: _kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Pesan
          _SectionLabel(
            icon: Icons.message_rounded,
            label: 'Pesan',
          ),
          const SizedBox(height: 8),
          const Text(
            _kPesan,
            style: TextStyle(
              color: _kTextMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          // Kesan
          _SectionLabel(
            icon: Icons.favorite_rounded,
            label: 'Kesan',
          ),
          const SizedBox(height: 8),
          const Text(
            _kKesan,
            style: TextStyle(
              color: _kTextMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Label sub-section di dalam kartu Pesan & Kesan
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kPrimary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget menu tile
// ---------------------------------------------------------------------------
class _MenuTile extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       label;
  final String       sublabel;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E0DB)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: const TextStyle(
                          color: _kTextMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB0B0B0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
