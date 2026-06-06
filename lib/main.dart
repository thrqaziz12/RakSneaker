import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<UserModel>('users');
  runApp(const RakSneakerApp());
}

class RakSneakerApp extends StatelessWidget {
  const RakSneakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RakSneaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          // Warna seed: Oranye Sneaker — energik, khas kultur sneaker
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: const LoginScreen(),
    );
  }
}
