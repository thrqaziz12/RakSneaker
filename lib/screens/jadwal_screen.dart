// =============================================================================
// jadwal_screen.dart
// Layar Jadwal Perawatan Sepatu:
//   - Tampilkan daftar jadwal
//   - Tambah jadwal baru (nama sepatu, merek, tanggal+waktu, keterangan)
//   - Hapus jadwal
//   - Notifikasi dijadwalkan otomatis beberapa menit atau saat waktu perawatan
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final JadwalService _jadwalService = JadwalService();
  final NotificationService _notifService = NotificationService();
  List<JadwalModel> _jadwalList = [];
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  /// Ambil userId dari SharedPreferences lalu muat jadwal.
  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // TODO: Sesuaikan key 'userId' dengan key yang dipakai di AuthService.
    _userId = prefs.getInt('userId') ?? 0;
    await _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    final list = await _jadwalService.getAllJadwal(_userId);
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
      await _jadwalService.hapusJadwal(jadwal.id, _userId);
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
        userId: _userId,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
        if (mendatang.isNotEmpty)
          ..._buildSection('Mendatang', mendatang, false),
        if (lewat.isNotEmpty) ..._buildSection('Sudah Lewat', lewat, true),
      ],
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
                  fontWeight: FontWeight.w600,
                  color: isPast ? _kTextMuted : _kPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      ...list.map(
        (jadwal) => _JadwalCard(
          jadwal: jadwal,
          isPast: isPast,
          onDelete: () => _hapusJadwal(jadwal),
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// _JadwalCard — Widget kartu untuk satu item jadwal
// ---------------------------------------------------------------------------
class _JadwalCard extends StatelessWidget {
  final JadwalModel jadwal;
  final bool isPast;
  final VoidCallback onDelete;

  const _JadwalCard({
    required this.jadwal,
    required this.isPast,
    required this.onDelete,
  });

  String _formatTanggal(DateTime dt) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
  }

  String _formatWaktu(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isPast ? const Color(0xFFF5F5F5) : _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPast ? const Color(0xFFE0E0E0) : _kBorder,
            width: 1,
          ),
          boxShadow: isPast
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon sneaker
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPast
                          ? const Color(0xFFE0E0E0)
                          : _kPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      MdiIcons.shoeSneaker,
                      color: isPast ? _kTextMuted : _kPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nama + merek
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jadwal.namaSepatu,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isPast ? _kTextMuted : _kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          jadwal.merekSepatu,
                          style: TextStyle(
                            fontSize: 13,
                            color: isPast ? _kTextMuted : _kPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol hapus
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFE57373),
                    ),
                    tooltip: 'Hapus jadwal',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: _kBorder, height: 1),
              const SizedBox(height: 12),
              // Tanggal + Waktu
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: _formatTanggal(jadwal.tanggalWaktu),
                    isPast: isPast,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: _formatWaktu(jadwal.tanggalWaktu),
                    isPast: isPast,
                  ),
                ],
              ),
              if (jadwal.keterangan.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 15,
                      color: isPast ? _kTextMuted : _kTextMuted,
                    ),
                    const SizedBox(width: 6),
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
                    Text(
                      _kNotifMinutesBefore == 0
                          ? 'Notifikasi tepat saat waktu perawatan'
                          : 'Notifikasi $_kNotifMinutesBefore menit sebelum perawatan',
                      style: TextStyle(
                        fontSize: 11,
                        color: _kPrimary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
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
                  const Text(
                    'Tambah Jadwal Perawatan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
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
              _buildLabel('Tanggal & Waktu Perawatan', required: true),
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
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Pilih Waktu',
                      hasValue: _selectedTime != null,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Keterangan
              _buildLabel('Keterangan', required: false),
              const SizedBox(height: 6),
              TextFormField(
                controller: _keteranganCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Cuci pakai sabun khusus, sikat halus...',
                  hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
                  filled: true,
                  fillColor: _kBg,
                  contentPadding: const EdgeInsets.all(14),
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
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Info notifikasi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: _kPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _kNotifMinutesBefore == 0
                            ? 'Notifikasi otomatis akan muncul tepat saat waktu perawatan.'
                            : 'Notifikasi otomatis akan muncul $_kNotifMinutesBefore menit sebelum waktu perawatan.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
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
            style: TextStyle(color: Color(0xFFE53935), fontSize: 14),
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
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: _kTextMuted, size: 20),
        filled: true,
        fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: hasValue ? _kPrimary.withValues(alpha: 0.07) : _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? _kPrimary : _kBorder,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hasValue ? _kPrimary : _kTextMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? _kPrimary : _kTextMuted,
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
