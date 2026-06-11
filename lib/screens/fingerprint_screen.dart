// =============================================================================
// fingerprint_screen.dart
// Halaman manajemen Sidik Jari untuk RakSneaker.
//
// Flow:
//   1. User sudah login (username tersedia)
//   2. Buka halaman ini dari ProfileScreen
//   3. Tekan tombol "Tambah Sidik Jari"
//   4. App memanggil local_auth (LocalAuthentication) untuk verifikasi
//      sidik jari NYATA dari sensor hardware perangkat
//   5. Jika berhasil → simpan record ke Hive box 'fingerprints'
//   6. Daftar sidik jari terdaftar tampil di list
//   7. User dapat menghapus sidik jari
//
// Implementasi:
//   Menggunakan package local_auth ^2.3.0 untuk autentikasi biometrik nyata.
//   Sensor fingerprint hardware perangkat dipanggil via LocalAuthentication.
//   Fallback graceful jika perangkat tidak mendukung biometrik.
//
// Tema: Light Mode Sneaker — Oranye #FF6B35
// =============================================================================

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/fingerprint_model.dart';
import '../services/biometric_service.dart';

const _kPrimary = Color(0xFFFF6B35);
const _kPrimaryDark = Color(0xFFD94F1A);
const _kBg = Color(0xFFFFF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kSurfaceAccent = Color(0xFFFFF0E8);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextMuted = Color(0xFF6B6B6B);
const _kTextFaint = Color(0xFFB0B0B0);
const _kBorder = Color(0xFFE8E0DB);
const _kSuccess = Color(0xFF2E7D32);
const _kSuccessBg = Color(0xFFE8F5E9);
const _kError = Color(0xFFD92B4B);

class FingerprintScreen extends StatefulWidget {
  final String username;
  const FingerprintScreen({super.key, required this.username});

  @override
  State<FingerprintScreen> createState() => _FingerprintScreenState();
}

class _FingerprintScreenState extends State<FingerprintScreen>
    with SingleTickerProviderStateMixin {
  late Box<FingerprintModel> _box;
  bool _boxReady = false;

  final _biometricService = BiometricService();
  bool _isBiometricSupported = false;
  bool _isBiometricEnrolled = false;

  // Animasi tombol pulse saat scanning
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initBox();
    _checkBiometricStatus();
  }

  Future<void> _initBox() async {
    _box = await Hive.openBox<FingerprintModel>('fingerprints');
    if (mounted) setState(() => _boxReady = true);
  }

  Future<void> _checkBiometricStatus() async {
    final supported = await _biometricService.isDeviceSupported();
    final enrolled = await _biometricService.canCheckBiometrics();
    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
        _isBiometricEnrolled = enrolled;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Daftar sidik jari milik user yang sedang login
  List<FingerprintModel> get _myFingerprints => _boxReady
      ? _box.values
            .where((f) => f.username == widget.username)
            .toList()
            .reversed
            .toList()
      : [];

  // -------------------------------------------------------------------
  // Dialog tambah sidik jari — memanggil sensor biometrik NYATA
  // -------------------------------------------------------------------
  void _showAddDialog() {
    // Jika perangkat tidak support biometrik, tampilkan info
    if (!_isBiometricSupported) {
      _showInfoSnackbar(
        'Perangkat ini tidak mendukung autentikasi biometrik.',
        isError: true,
      );
      return;
    }
    if (!_isBiometricEnrolled) {
      _showInfoSnackbar(
        'Tidak ada sidik jari terdaftar di perangkat. Silakan daftarkan dulu di Pengaturan → Keamanan.',
        isError: true,
      );
      return;
    }

    final labelController = TextEditingController();
    bool isScanning = false;
    bool scanned = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: !isScanning,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            // Fungsi yang memanggil sensor biometrik nyata
            Future<void> scanFingerprint() async {
              setDlgState(() {
                isScanning = true;
                errorMsg = null;
              });

              final result = await _biometricService.authenticate(
                reason:
                    'Tempelkan jari Anda pada sensor untuk mendaftarkan sidik jari ke RakSneaker',
              );

              if (!ctx.mounted) return;

              if (result.success) {
                setDlgState(() {
                  isScanning = false;
                  scanned = true;
                  errorMsg = null;
                });
              } else {
                setDlgState(() {
                  isScanning = false;
                  scanned = false;
                  errorMsg = result.message;
                });
              }
            }

            return AlertDialog(
              backgroundColor: _kSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Tambah Sidik Jari',
                style: TextStyle(
                  color: _kTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label input
                    TextField(
                      controller: labelController,
                      style: const TextStyle(color: _kTextPrimary),
                      decoration: InputDecoration(
                        hintText:
                            'Nama sidik jari (contoh: Jari Telunjuk Kanan)',
                        hintStyle: const TextStyle(color: _kTextFaint),
                        filled: true,
                        fillColor: _kBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _kPrimary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol scan sidik jari — memanggil sensor hardware nyata
                    GestureDetector(
                      onTap: scanned || isScanning ? null : scanFingerprint,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: scanned
                              ? _kSuccessBg
                              : isScanning
                              ? _kPrimary.withValues(alpha: 0.12)
                              : _kSurfaceAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scanned
                                ? _kSuccess
                                : isScanning
                                ? _kPrimary
                                : _kPrimary.withValues(alpha: 0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (scanned ? _kSuccess : _kPrimary)
                                  .withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: isScanning
                            ? const Padding(
                                padding: EdgeInsets.all(28),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _kPrimary,
                                ),
                              )
                            : Icon(
                                Icons.fingerprint_rounded,
                                size: 52,
                                color: scanned ? _kSuccess : _kPrimary,
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      scanned
                          ? 'Sidik jari terverifikasi ✓'
                          : isScanning
                          ? 'Menunggu sensor…'
                          : 'Ketuk ikon untuk memindai',
                      style: TextStyle(
                        color: scanned
                            ? _kSuccess
                            : isScanning
                            ? _kPrimary
                            : _kTextMuted,
                        fontSize: 13,
                        fontWeight: scanned
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),

                    // Tampilkan pesan error jika autentikasi gagal
                    if (errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _kError.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _kError.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: _kError,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                errorMsg!,
                                style: const TextStyle(
                                  color: _kError,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: _kTextMuted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scanned ? _kPrimary : _kBorder,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: scanned ? 2 : 0,
                  ),
                  onPressed: scanned
                      ? () async {
                          final rawLabel = labelController.text.trim();
                          final label = rawLabel.isEmpty
                              ? 'Sidik Jari ${_myFingerprints.length + 1}'
                              : rawLabel;
                          final now = DateTime.now();
                          final dateStr =
                              '${now.day.toString().padLeft(2, '0')}'
                              '/${now.month.toString().padLeft(2, '0')}'
                              '/${now.year} '
                              '${now.hour.toString().padLeft(2, '0')}:'
                              '${now.minute.toString().padLeft(2, '0')}';
                          await _box.add(
                            FingerprintModel(
                              username: widget.username,
                              label: label,
                              addedAt: dateStr,
                            ),
                          );
                          if (mounted) {
                            setState(() {});
                            Navigator.pop(context);
                            _showSuccessSnackbar(label);
                          }
                        }
                      : null,
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessSnackbar(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kSuccess,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '"$label" berhasil ditambahkan',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _kError : _kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _deleteFingerprint(FingerprintModel fp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Sidik Jari',
          style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Hapus "${fp.label}"?',
          style: const TextStyle(color: _kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _kTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await fp.delete();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final fps = _myFingerprints;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _kTextPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        title: const Text(
          'Sidik Jari',
          style: TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded, size: 18, color: _kPrimary),
            label: const Text(
              'Tambah',
              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !_boxReady
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : Column(
              children: [
                // Banner status biometrik
                if (!_isBiometricSupported || !_isBiometricEnrolled)
                  _buildBiometricWarning(),
                Expanded(
                  child: fps.isEmpty ? _buildEmptyState() : _buildList(fps),
                ),
              ],
            ),
    );
  }

  // Banner peringatan jika biometrik tidak siap
  Widget _buildBiometricWarning() {
    final msg = !_isBiometricSupported
        ? 'Perangkat ini tidak mendukung biometrik'
        : 'Belum ada sidik jari di perangkat. Daftarkan dulu di Pengaturan → Keamanan.';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kError.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kError, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: _kError, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Empty state
  // -------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _kSurfaceAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kPrimary.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 64,
                  color: _kPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada sidik jari',
              style: TextStyle(
                color: _kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan sidik jari untuk autentikasi lebih mudah ke aplikasi RakSneaker.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Tambah Sidik Jari',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: _kPrimary.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // List sidik jari terdaftar
  // -------------------------------------------------------------------
  Widget _buildList(List<FingerprintModel> fps) {
    return Column(
      children: [
        // Header info
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _kSurfaceAccent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _kPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${fps.length} sidik jari terdaftar untuk akun "${widget.username}"',
                  style: const TextStyle(
                    color: _kPrimaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: fps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final fp = fps[i];
              return _FingerprintTile(
                fingerprint: fp,
                index: fps.length - i,
                onDelete: () => _deleteFingerprint(fp),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tile item sidik jari
// ---------------------------------------------------------------------------
class _FingerprintTile extends StatelessWidget {
  final FingerprintModel fingerprint;
  final int index;
  final VoidCallback onDelete;

  const _FingerprintTile({
    required this.fingerprint,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kSurfaceAccent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.20)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  color: _kPrimary,
                  size: 28,
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: _kSuccess,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fingerprint.label,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ditambahkan ${fingerprint.addedAt}',
                  style: const TextStyle(color: _kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: _kError,
              size: 20,
            ),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }
}
