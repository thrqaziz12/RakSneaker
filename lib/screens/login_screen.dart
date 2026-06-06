// =============================================================================
// login_screen.dart — RakSneaker (Light Theme)
// =============================================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

// ---------------------------------------------------------------------------
// Konstanta Warna — Light Theme / Sneaker Collection
// ---------------------------------------------------------------------------
const kPrimary      = Color(0xFFFF6B35); // Oranye sneaker (aksen utama)
const kPrimaryDark  = Color(0xFFD94F1A); // Hover / gradient bawah
const kBg           = Color(0xFFFAF9F7); // Background putih hangat
const kSurface      = Color(0xFFFFFFFF); // Card / input putih
const kSurfaceOff   = Color(0xFFF5F4F0); // Surface sedikit abu
const kTextDark     = Color(0xFF1A1714); // Teks utama
const kTextMid      = Color(0xFF6B6560); // Teks sekunder
const kTextLight    = Color(0xFFB0ABA6); // Placeholder
const kBorder       = Color(0xFFE8E5E1); // Border input
const kError        = Color(0xFFD93025); // Error merah

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey             = GlobalKey<FormState>();
  final _usernameController  = TextEditingController();
  final _passwordController  = TextEditingController();
  final _authService         = AuthService();

  bool    _isLoading       = false;
  bool    _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    await Future.delayed(const Duration(milliseconds: 600));
    final user = _authService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(username: user.username)),
      );
    } else {
      setState(() => _errorMessage = 'Username atau password salah');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height
                - MediaQuery.of(context).padding.top
                - MediaQuery.of(context).padding.bottom,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 56),

                      // ── Logo & Judul ──────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            // Logo container dengan SVG sepatu
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B35), Color(0xFFD94F1A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimary.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              // SVG sepatu sneaker (inline CustomPaint)
                              child: const _SneakerLogoIcon(),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'RakSneaker',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: kTextDark,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Koleksi sneakermu, tertata rapi',
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextMid,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Masuk ke akunmu',
                              style: TextStyle(fontSize: 14, color: kTextLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),

                      // ── Form ─────────────────────────────────────────────
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _usernameController,
                              label: 'Username',
                              hint: 'Masukkan username',
                              icon: Icons.person_outline_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Masukkan password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: kTextLight,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── Error ─────────────────────────────────────────────
                      if (_errorMessage != null) ...[  
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: kError.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: kError.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: kError, size: 18),
                              const SizedBox(width: 8),
                              Text(_errorMessage!,
                                  style: const TextStyle(
                                      color: kError, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Tombol Login ──────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Text('Masuk',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                        ),
                      ),

                      const Spacer(),

                      // ── Link Register ─────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(
                                    color: kTextMid, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Daftar sekarang',
                                    style: TextStyle(
                                        color: kPrimary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: kTextDark, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextLight),
            prefixIcon: Icon(icon, color: kTextLight, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kError, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kError, width: 1.5),
            ),
            errorStyle: const TextStyle(color: kError),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _SneakerLogoIcon — CustomPainter logo sepatu sneaker
// =============================================================================
class _SneakerLogoIcon extends StatelessWidget {
  const _SneakerLogoIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(88, 88),
      painter: _SneakerPainter(),
    );
  }
}

class _SneakerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // ── Sol bawah (outsole) ─────────────────────────────────────────────────
    final solePath = Path()
      ..moveTo(w * 0.12, h * 0.70)
      ..quadraticBezierTo(w * 0.10, h * 0.82, w * 0.22, h * 0.84)
      ..lineTo(w * 0.78, h * 0.84)
      ..quadraticBezierTo(w * 0.92, h * 0.83, w * 0.88, h * 0.72)
      ..lineTo(w * 0.12, h * 0.70)
      ..close();
    canvas.drawPath(solePath, paint);

    // ── Upper (badan sepatu) ───────────────────────────────────────────────
    final upperPath = Path()
      ..moveTo(w * 0.18, h * 0.70)
      ..quadraticBezierTo(w * 0.16, h * 0.52, w * 0.30, h * 0.44)
      ..quadraticBezierTo(w * 0.42, h * 0.36, w * 0.58, h * 0.38)
      ..lineTo(w * 0.75, h * 0.44)
      ..quadraticBezierTo(w * 0.86, h * 0.50, w * 0.84, h * 0.60)
      ..lineTo(w * 0.86, h * 0.70)
      ..lineTo(w * 0.18, h * 0.70)
      ..close();
    canvas.drawPath(upperPath, paint);

    // ── Lidah sepatu (tongue) ─────────────────────────────────────────────
    final tonguePath = Path()
      ..moveTo(w * 0.33, h * 0.44)
      ..quadraticBezierTo(w * 0.31, h * 0.34, w * 0.36, h * 0.26)
      ..lineTo(w * 0.52, h * 0.26)
      ..quadraticBezierTo(w * 0.56, h * 0.34, w * 0.54, h * 0.44)
      ..close();
    // Warna berbeda: putih lebih transparan untuk efek kedalaman
    canvas.drawPath(tonguePath,
        paint..color = Colors.white.withValues(alpha: 0.75));

    // ── Tali sepatu (laces) ───────────────────────────────────────────────
    final lacePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3 pasang tali
    for (int i = 0; i < 3; i++) {
      final y = h * (0.30 + i * 0.055);
      canvas.drawLine(
        Offset(w * 0.345, y),
        Offset(w * 0.505, y),
        lacePaint,
      );
    }

    // ── Stripe dekoratif di sisi upper ────────────────────────────────────
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stripe1 = Path()
      ..moveTo(w * 0.60, h * 0.48)
      ..quadraticBezierTo(w * 0.68, h * 0.52, w * 0.72, h * 0.62);
    canvas.drawPath(stripe1, stripePaint);

    final stripe2 = Path()
      ..moveTo(w * 0.66, h * 0.50)
      ..quadraticBezierTo(w * 0.74, h * 0.55, w * 0.77, h * 0.64);
    canvas.drawPath(stripe2, stripePaint);
  }

  @override
  bool shouldRepaint(_SneakerPainter oldDelegate) => false;
}
