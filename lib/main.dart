import 'package:flutter/material.dart';
import 'core/database_helper.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

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

  runApp(const RakSneakerApp());
}

class RakSneakerApp extends StatelessWidget {
  const RakSneakerApp({super.key});

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
      home: const LoginScreen(),
    );
  }
}
