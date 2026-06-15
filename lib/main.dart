import 'package:flutter/material.dart';
import 'core/database_helper.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';

// =============================================================================
// Global NavigatorKey — dipakai untuk navigasi dari luar widget tree
// (contoh: logout dari ProfileScreen yang ada di dalam IndexedStack).
// =============================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi SQLite — membuat tabel jika belum ada
  await DatabaseHelper().database;

  // Inisialisasi NotificationService
  await NotificationService().init();

  // Cek sesi login aktif
  final sessionService = SessionService();
  final isLoggedIn   = await sessionService.isLoggedIn();
  final username     = await sessionService.getUsername();
  final userId       = await sessionService.getUserId();

  runApp(RakSneakerApp(
    isLoggedIn: isLoggedIn,
    username:   username ?? '',
    userId:     userId,
  ));
}

class RakSneakerApp extends StatelessWidget {
  final bool   isLoggedIn;
  final String username;
  final int    userId;

  const RakSneakerApp({
    super.key,
    required this.isLoggedIn,
    required this.username,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RakSneaker',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // <-- daftarkan global key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFFFFF8F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF8F5),
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
      ),
      // Jika sesi aktif → langsung ke MainScreen, jika tidak → LoginScreen
      home: isLoggedIn
          ? MainScreen(username: username, userId: userId)
          : const LoginScreen(),
    );
  }
}
