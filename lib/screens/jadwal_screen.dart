// =============================================================================
// jadwal_screen.dart
// Layar Jadwal Perawatan Sepatu:
//   - Tampilkan daftar jadwal
//   - Tambah jadwal baru (nama sepatu, merek, tanggal+waktu, keterangan)
//   - Hapus jadwal
//   - Notifikasi dijadwalkan otomatis beberapa menit atau saat waktu perawatan
//   - Konversi zona waktu: WIB, WITA, WIT, dan London
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';
import '../services/notification_service.dart';

const _kPrimary = Color(0xFFFF6B35);
const _kBg = Color(0xFFFFF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextMuted = Color(0xFF6B6B6B);
const _kBorder = Color(0xFFE8E0DB);

// Konstanta minutesBefore terpusat — ubah di sini untuk
// mengubah kapan notifikasi muncul di seluruh aplikasi.
const int _kNotifMinutesBefore = 30;

// ---------------------------------------------------------------------------
// Helper konversi zona waktu
// ---------------------------------------------------------------------------

/// Zona waktu yang didukung untuk konversi tampilan jadwal.
enum ZonaWaktu { wib, wita, wit, london }

extension ZonaWaktuExt on ZonaWaktu {
  String get label {
    switch (this) {
      case ZonaWaktu.wib:
        return 'WIB';
      case ZonaWaktu.wita:
        return 'WITA';
      case ZonaWaktu.wit:
        return 'WIT';
      case ZonaWaktu.london:
        return 'London';
    }
  }

  /// Offset UTC dalam jam untuk setiap zona waktu.
  /// London mengikuti BST (UTC+1) saat musim panas (Mar–Okt) dan GMT (UTC+0) saat musim dingin.
  int offsetJam(DateTime dt) {
    switch (this) {
      case ZonaWaktu.wib:
        return 7; // UTC+7
      case ZonaWaktu.wita:
        return 8; // UTC+8
      case ZonaWaktu.wit:
        return 9; // UTC+9
      case ZonaWaktu.london:
        // BST aktif dari akhir Maret hingga akhir Oktober
        return _isBST(dt) ? 1 : 0;
    }
  }

  /// Cek apakah tanggal termasuk periode British Summer Time (BST).
  /// BST berlaku dari Minggu terakhir Maret hingga Minggu terakhir Oktober.
  bool _isBST(DateTime dt) {
    if (dt.month < 3 || dt.month > 10) return false;
    if (dt.month > 3 && dt.month < 10) return true;
    // Hitung Minggu terakhir Maret
    if (dt.month == 3) {
      final lastSunday = _lastSundayOfMonth(dt.year, 3);
      return dt.day >= lastSunday;
    }
    // Hitung Minggu terakhir Oktober
    final lastSunday = _lastSundayOfMonth(dt.year, 10);
    return dt.day < lastSunday;
  }

  int _lastSundayOfMonth(int year, int month) {
    // Mulai dari hari terakhir bulan tersebut, mundur hingga Minggu
    final lastDay = DateTime(year, month + 1, 0);
    return lastDay.day - lastDay.weekday % 7;
  }
}

/// Konversi DateTime (WIB = UTC+7) ke zona waktu yang dipilih.
/// Asumsi: DateTime dari database disimpan dalam zona WIB (UTC+7).
DateTime konversiKeZona(DateTime dtWib, ZonaWaktu zona) {
  // Konversi ke UTC dulu, lalu tambahkan offset target
  final utc = dtWib.subtract(const Duration(hours: 7));
  final offset = zona.offsetJam(dtWib);
  return utc.add(Duration(hours: offset));
}

// ---------------------------------------------------------------------------

class JadwalScreen extends StatefulWidget {
  final int userId;
  const JadwalScreen({super.key, required this.userId});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final JadwalService _jadwalService = JadwalService();
  final NotificationService _notifService = NotificationService();
  List<JadwalModel> _jadwalList = [];

  /// Zona waktu yang sedang dipilih pengguna untuk tampilan
  ZonaWaktu _zonaAktif = ZonaWaktu.wib;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    final list = await _jadwalService.getAllJadwal(widget.userId);
    if (mounted) {
      setState(() {
        _jadwalList = list;
      });
    }
  }

  Future<void> _hapusJadwal(JadwalModel jadwal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jadwal?'),
        content: Text(
          'Jadwal perawatan "${jadwal.namaSepatu}" akan dihapus.\nNotifikasi juga akan dibatalkan.',
          style: const TextStyle(color: _kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _notifService.cancelJadwalNotification(jadwal.id);
      await _jadwalService.hapusJadwal(jadwal.id, widget.userId);
      await _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Jadwal berhasil dihapus'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showTambahJadwalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TambahJadwalSheet(
        userId: widget.userId,
        onSave: (jadwal) async {
          await _jadwalService.tambahJadwal(jadwal);
          await _notifService.scheduleJadwalNotification(
            jadwal,
            minutesBefore: _kNotifMinutesBefore,
          );
          await _loadJadwal();
          if (mounted) {
            final infoTeks = _kNotifMinutesBefore == 0
                ? 'Notifikasi akan muncul tepat saat jadwal.'
                : 'Notifikasi akan muncul $_kNotifMinutesBefore menit sebelumnya.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Jadwal disimpan! $infoTeks'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  /// Tampilkan bottom sheet pemilih zona waktu
  void _showZonaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.public_rounded, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pilih Zona Waktu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Waktu jadwal akan dikonversi ke zona yang dipilih.',
              style: TextStyle(fontSize: 13, color: _kTextMuted),
            ),
            const SizedBox(height: 16),
            ...ZonaWaktu.values.map((zona) {
              final isActive = zona == _zonaAktif;
              final now = DateTime.now();
              final converted = konversiKeZona(now, zona);
              final previewStr =
                  '${converted.hour.toString().padLeft(2, '0')}:${converted.minute.toString().padLeft(2, '0')} ${zona.label}';
              return GestureDetector(
                onTap: () {
                  setState(() => _zonaAktif = zona);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _kPrimary.withValues(alpha: 0.08)
                        : const Color(0xFFFAF8F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? _kPrimary : _kBorder,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: isActive ? _kPrimary : _kTextMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _zonaLabel(zona),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isActive ? _kPrimary : _kTextPrimary,
                              ),
                            ),
                            Text(
                              _zonaDescription(zona, now),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        previewStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? _kPrimary : _kTextMuted,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: _kPrimary),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _zonaLabel(ZonaWaktu zona) {
    switch (zona) {
      case ZonaWaktu.wib:
        return 'WIB — Waktu Indonesia Barat';
      case ZonaWaktu.wita:
        return 'WITA — Waktu Indonesia Tengah';
      case ZonaWaktu.wit:
        return 'WIT — Waktu Indonesia Timur';
      case ZonaWaktu.london:
        return 'London (GMT/BST)';
    }
  }

  String _zonaDescription(ZonaWaktu zona, DateTime dt) {
    switch (zona) {
      case ZonaWaktu.wib:
        return 'Jakarta, Bandung, Surabaya · UTC+7';
      case ZonaWaktu.wita:
        return 'Makassar, Bali, Lombok · UTC+8';
      case ZonaWaktu.wit:
        return 'Jayapura, Ambon, Sorong · UTC+9';
      case ZonaWaktu.london:
        final bst = ZonaWaktu.london._isBST(dt);
        return bst ? 'British Summer Time · UTC+1' : 'Greenwich Mean Time · UTC+0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Row(
          children: [
            Icon(MdiIcons.calendarCheck, color: _kPrimary, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Jadwal Perawatan',
              style: TextStyle(
                color: _kTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          // Tombol pemilih zona waktu
          GestureDetector(
            onTap: _showZonaPicker,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public_rounded, size: 14, color: _kPrimary),
                  const SizedBox(width: 4),
                  Text(
                    _zonaAktif.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: 16, color: _kPrimary),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              onPressed: _showTambahJadwalSheet,
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text(
                'Tambah',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: _jadwalList.isEmpty ? _buildEmptyState() : _buildJadwalList(),
    );
  }

  // FIX #1: Bungkus Column dengan SingleChildScrollView agar tidak overflow
  // ke bawah (error baris ~223) ketika konten lebih tinggi dari layar.
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                MdiIcons.calendarBlankOutline,
                size: 52,
                color: _kPrimary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Jadwal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan jadwal perawatan sneaker kamu agar tidak terlewat!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showTambahJadwalSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Jadwal Pertama',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalList() {
    // Pisahkan jadwal mendatang dan yang sudah lewat
    final now = DateTime.now();
    final mendatang = _jadwalList
        .where((j) => j.tanggalWaktu.isAfter(now))
        .toList();
    final lewat = _jadwalList
        .where((j) => !j.tanggalWaktu.isAfter(now))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Banner zona waktu aktif
        _buildZonaBanner(),
        if (mendatang.isNotEmpty)
          ..._buildSection('Mendatang', mendatang, false),
        if (lewat.isNotEmpty) ..._buildSection('Sudah Lewat', lewat, true),
      ],
    );
  }

  /// Banner kecil menampilkan zona waktu yang sedang aktif
  Widget _buildZonaBanner() {
    final now = DateTime.now();
    final converted = konversiKeZona(now, _zonaAktif);
    final desc = _zonaDescription(_zonaAktif, now);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.public_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tampil dalam ${_zonaAktif.label} · $desc',
              style: TextStyle(
                fontSize: 12,
                color: _kPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Sekarang ${converted.hour.toString().padLeft(2, '0')}:${converted.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              color: _kPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSection(
    String title,
    List<JadwalModel> list,
    bool isPast,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: isPast ? _kTextMuted : _kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPast ? _kTextMuted : _kTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPast
                    ? _kTextMuted.withValues(alpha: 0.1)
                    : _kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${list.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPast ? _kTextMuted : _kPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      ...list.map((j) => _buildJadwalCard(j, isPast)),
    ];
  }

  Widget _buildJadwalCard(JadwalModel jadwal, bool isPast) {
    // Konversi ke zona waktu yang dipilih
    final dtKonversi = konversiKeZona(jadwal.tanggalWaktu, _zonaAktif);
    final timeStr =
        '${dtKonversi.hour.toString().padLeft(2, '0')}:${dtKonversi.minute.toString().padLeft(2, '0')} ${_zonaAktif.label}';
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final dateStr =
        '${dtKonversi.day} ${bulan[dtKonversi.month - 1]} ${dtKonversi.year}';

    return Dismissible(
      key: Key(jadwal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _hapusJadwal(jadwal);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPast
                ? _kBorder
                : _kPrimary.withValues(alpha: 0.25),
            width: isPast ? 1 : 1.5,
          ),
          boxShadow: isPast
              ? null
              : [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPast
                          ? const Color(0xFFEEEEEE)
                          : _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      MdiIcons.shoeSneaker,
                      size: 26,
                      color: isPast ? _kTextMuted : _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jadwal.namaSepatu,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isPast ? _kTextMuted : _kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          jadwal.merekSepatu,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _hapusJadwal(jadwal),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // FIX #2: Ganti Row biasa dengan Wrap agar chip tidak overflow
              // ke kanan (error baris ~374) ketika teks chip panjang.
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: dateStr,
                    isPast: isPast,
                  ),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: timeStr,
                    isPast: isPast,
                  ),
                ],
              ),
              // Tampilkan konversi waktu di semua zona lain
              const SizedBox(height: 8),
              _buildKonversiRow(jadwal.tanggalWaktu, isPast),
              if (jadwal.keterangan.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 14,
                      color: _kTextMuted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        jadwal.keterangan,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kTextMuted,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (!isPast) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      size: 13,
                      color: _kPrimary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _kNotifMinutesBefore == 0
                            ? 'Notifikasi tepat saat waktu perawatan'
                            : 'Notifikasi $_kNotifMinutesBefore menit sebelum perawatan',
                        style: TextStyle(
                          fontSize: 11,
                          color: _kPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Baris konversi waktu semua zona (minus zona yang sedang aktif)
  Widget _buildKonversiRow(DateTime dtWib, bool isPast) {
    final zonaLain = ZonaWaktu.values.where((z) => z != _zonaAktif).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: zonaLain.map((zona) {
        final converted = konversiKeZona(dtWib, zona);
        final jam =
            '${converted.hour.toString().padLeft(2, '0')}:${converted.minute.toString().padLeft(2, '0')}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPast
                ? const Color(0xFFEEEEEE)
                : _kPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPast
                  ? _kBorder
                  : _kPrimary.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            '${zona.label} $jam',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPast ? _kTextMuted : _kTextMuted,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPast;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPast
            ? const Color(0xFFEEEEEE)
            : _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isPast ? _kTextMuted : _kPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPast ? _kTextMuted : _kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TambahJadwalSheet — Bottom sheet form untuk tambah jadwal baru
// ---------------------------------------------------------------------------
class _TambahJadwalSheet extends StatefulWidget {
  final int userId;
  final Future<void> Function(JadwalModel jadwal) onSave;

  const _TambahJadwalSheet({
    required this.userId,
    required this.onSave,
  });

  @override
  State<_TambahJadwalSheet> createState() => _TambahJadwalSheetState();
}

class _TambahJadwalSheetState extends State<_TambahJadwalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _merekCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _merekCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime dt) {
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
  }

  /// Tampilkan preview konversi waktu di semua zona berdasarkan input pengguna
  Widget _buildKonversiPreview() {
    if (_selectedDate == null || _selectedTime == null) {
      return const SizedBox.shrink();
    }
    final dtWib = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.public_rounded, size: 14, color: _kPrimary),
            const SizedBox(width: 6),
            const Text(
              'Konversi Zona Waktu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: ZonaWaktu.values.map((zona) {
            final converted = konversiKeZona(dtWib, zona);
            final jam =
                '${converted.hour.toString().padLeft(2, '0')}:${converted.minute.toString().padLeft(2, '0')}';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zona.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  Text(
                    jam,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          '* Input waktu diasumsikan dalam WIB (UTC+7)',
          style: TextStyle(fontSize: 11, color: _kTextMuted),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final tanggalWaktu = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final jadwal = JadwalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      namaSepatu: _namaCtrl.text.trim(),
      merekSepatu: _merekCtrl.text.trim(),
      tanggalWaktu: tanggalWaktu,
      keterangan: _keteranganCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await widget.onSave(jadwal);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      MdiIcons.calendarPlus,
                      color: _kPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tambah Jadwal Perawatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Field Nama Sepatu
              _buildLabel('Nama Sepatu', required: true),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _namaCtrl,
                hint: 'Contoh: Air Force 1 White',
                icon: MdiIcons.shoeSneaker,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama sepatu wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              // Field Merek Sepatu
              _buildLabel('Merek Sepatu', required: true),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _merekCtrl,
                hint: 'Contoh: Nike, Adidas, New Balance',
                icon: Icons.label_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Merek sepatu wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              // Tanggal & Waktu
              _buildLabel('Tanggal & Waktu Perawatan (WIB)', required: true),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.calendar_today_rounded,
                      label: _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Pilih Tanggal',
                      hasValue: _selectedDate != null,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.access_time_rounded,
                      label: _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} WIB'
                          : 'Pilih Waktu',
                      hasValue: _selectedTime != null,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              // Preview konversi zona waktu
              _buildKonversiPreview(),
              const SizedBox(height: 16),
              // Keterangan
              _buildLabel('Keterangan', required: false),
              const SizedBox(height: 6),
              TextFormField(
                controller: _keteranganCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Catatan perawatan (opsional)',
                  hintStyle:
                      const TextStyle(color: _kTextMuted, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Jadwal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool required}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: _kTextPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: _kTextMuted, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAF8F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PickerButton — tombol pemilih tanggal / waktu
// ---------------------------------------------------------------------------
class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue
              ? _kPrimary.withValues(alpha: 0.06)
              : const Color(0xFFFAF8F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? _kPrimary : _kBorder,
            width: hasValue ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: hasValue ? _kPrimary : _kTextMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue ? _kTextPrimary : _kTextMuted,
                  fontWeight:
                      hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
