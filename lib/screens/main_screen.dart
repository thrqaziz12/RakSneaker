// =============================================================================
// main_screen.dart
// Shell utama aplikasi RakSneaker dengan BottomNavigationBar.
//
// Tabs:
//   0 - Home     : Beranda koleksi sneaker
//   1 - Koleksi  : Kelola koleksi sepatu pribadi (tambah/edit/hapus)
//   2 - Jadwal   : Jadwal perawatan sepatu + local notification
//   3 - Lokasi   : Peta toko sepatu (OpenStreetMap + Geolocation)
//   4 - Profile  : Info akun + menu Sidik Jari
//
// Tema: Light Mode Sneaker — Oranye #FF6B35
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'home_screen.dart';
import 'koleksi_screen.dart';
import 'jadwal_screen.dart';
import 'lokasi_screen.dart';
import 'profile_screen.dart';

const kPrimaryColor   = Color(0xFFFF6B35);
const kBgLight        = Color(0xFFFFF8F5);
const kSurfaceLight   = Color(0xFFFFFFFF);
const kTextPrimary    = Color(0xFF1A1A1A);
const kTextMuted      = Color(0xFF6B6B6B);
const kBorderColor    = Color(0xFFE8E0DB);

class MainScreen extends StatefulWidget {
  final String username;
  final int userId;
  const MainScreen({super.key, required this.username, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(username: widget.username),
      KoleksiScreen(userId: widget.userId),
      JadwalScreen(userId: widget.userId),
      const LokasiScreen(),
      ProfileScreen(username: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurfaceLight,
          border: Border(
            top: BorderSide(color: kBorderColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: kSurfaceLight,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kTextMuted,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            // ── Tab 0: Home ──
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(MdiIcons.shoeSneaker),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(MdiIcons.shoeSneaker),
              ),
              label: 'Home',
            ),
            // ── Tab 1: Koleksi ──
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.collections_bookmark_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.collections_bookmark_rounded),
              ),
              label: 'Koleksi',
            ),
            // ── Tab 2: Jadwal ──
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.calendar_month_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.calendar_month_rounded),
              ),
              label: 'Jadwal',
            ),
            // ── Tab 3: Lokasi ──
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.location_on_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.location_on_rounded),
              ),
              label: 'Lokasi',
            ),
            // ── Tab 4: Profile ──
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_outline_rounded),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_rounded),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
