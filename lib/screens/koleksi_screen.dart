// =============================================================================
// koleksi_screen.dart
// Halaman Koleksi Sepatu — CRUD lengkap.
//
// Fitur:
//   - Tampilkan daftar koleksi sepatu user dalam grid card
//   - Tambah koleksi baru via bottom sheet form
//   - Edit koleksi via bottom sheet form (pre-filled)
//   - Hapus koleksi via dialog konfirmasi
//   - Setiap koleksi menyimpan: gambar (multi-URL), nama, merek, harga, keterangan
//
// Storage: Hive box 'koleksi'
// Tema: konsisten dengan app (Oranye #FF6B35)
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/koleksi_model.dart';

const _kPrimary    = Color(0xFFFF6B35);
const _kPrimaryBg  = Color(0xFFFFF8F5);
const _kSurface    = Color(0xFFFFFFFF);
const _kTextPri    = Color(0xFF1A1A1A);
const _kTextMuted  = Color(0xFF6B6B6B);
const _kBorder     = Color(0xFFE8E0DB);
const _kError      = Color(0xFFD32F2F);

// ─── Helper ──────────────────────────────────────────────────────────────────

String _formatRupiah(double value) {
  final parts = value.toStringAsFixed(0).split('');
  final result = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) result.write('.');
    result.write(parts[i]);
  }
  return 'Rp ${result.toString()}';
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class KoleksiScreen extends StatelessWidget {
  const KoleksiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPrimaryBg,
      appBar: AppBar(
        backgroundColor: _kPrimaryBg,
        foregroundColor: _kTextPri,
        elevation: 0,
        title: const Text(
          'Koleksi Sepatu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: _kTextPri,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: _kPrimary,
            iconSize: 28,
            tooltip: 'Tambah Koleksi',
            onPressed: () => _openForm(context, existing: null),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<KoleksiModel>('koleksi').listenable(),
        builder: (context, Box<KoleksiModel> box, _) {
          final items = box.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (items.isEmpty) {
            return _EmptyState(
              onAdd: () => _openForm(context, existing: null),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _KoleksiCard(
                item: items[index],
                onEdit: () => _openForm(context, existing: items[index]),
                onDelete: () => _confirmDelete(context, items[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, existing: null),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Buka form tambah / edit ──
  void _openForm(BuildContext context, {KoleksiModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KoleksiForm(existing: existing),
    );
  }

  // ── Dialog konfirmasi hapus ──
  void _confirmDelete(BuildContext context, KoleksiModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Koleksi?',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kTextPri),
        ),
        content: Text(
          'Koleksi "${item.namaSepatu}" akan dihapus secara permanen.',
          style: const TextStyle(color: _kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: _kTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              item.delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${item.namaSepatu}" dihapus'),
                  backgroundColor: _kError,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                MdiIcons.shoeSneaker,
                size: 48,
                color: _kPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada koleksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextPri,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan sepatu pertamamu dan mulai catat koleksimu!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kTextMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Koleksi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Koleksi ─────────────────────────────────────────────────────────────

class _KoleksiCard extends StatelessWidget {
  final KoleksiModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KoleksiCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = item.images.isNotEmpty;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gambar utama ──
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: hasImage
                    ? Image.network(
                        item.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF3F0EC),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kPrimary,
                              ),
                            ),
                          );
                        },
                      )
                    : _imagePlaceholder(),
              ),
            ),

            // ── Info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaSepatu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPri,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.merek,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTextMuted,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatRupiah(item.harga),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        // Tombol aksi
                        Row(
                          children: [
                            _ActionBtn(
                              icon: Icons.edit_rounded,
                              color: const Color(0xFF1976D2),
                              tooltip: 'Edit',
                              onTap: onEdit,
                            ),
                            const SizedBox(width: 4),
                            _ActionBtn(
                              icon: Icons.delete_rounded,
                              color: _kError,
                              tooltip: 'Hapus',
                              onTap: onDelete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF3F0EC),
      child: Center(
        child: Icon(
          MdiIcons.shoeSneaker,
          size: 40,
          color: _kPrimary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KoleksiDetail(item: item),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Detail View ─────────────────────────────────────────────────────────────

class _KoleksiDetail extends StatefulWidget {
  final KoleksiModel item;
  const _KoleksiDetail({required this.item});

  @override
  State<_KoleksiDetail> createState() => _KoleksiDetailState();
}

class _KoleksiDetailState extends State<_KoleksiDetail> {
  int _imgIdx = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imgs = item.images;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Gambar carousel ──
                  if (imgs.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: Image.network(
                          imgs[_imgIdx],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF3F0EC),
                            child: Icon(
                              MdiIcons.shoeSneaker,
                              size: 64,
                              color: _kPrimary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (imgs.length > 1) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imgs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => setState(() => _imgIdx = i),
                            child: Container(
                              width: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      _imgIdx == i ? _kPrimary : _kBorder,
                                  width: _imgIdx == i ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.network(
                                  imgs[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    size: 24,
                                    color: _kTextMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0EC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          MdiIcons.shoeSneaker,
                          size: 64,
                          color: _kPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Info sepatu ──
                  Text(
                    item.namaSepatu,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kTextPri,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.merek,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatRupiah(item.harga),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  if (item.keterangan.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Keterangan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPri,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.keterangan,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kTextMuted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form Tambah / Edit ───────────────────────────────────────────────────────

class _KoleksiForm extends StatefulWidget {
  final KoleksiModel? existing;
  const _KoleksiForm({this.existing});

  @override
  State<_KoleksiForm> createState() => _KoleksiFormState();
}

class _KoleksiFormState extends State<_KoleksiForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _merekCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _ketCtrl;
  late final TextEditingController _imgCtrl; // input URL gambar baru
  final List<String> _images = [];

  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _namaCtrl  = TextEditingController(text: e?.namaSepatu  ?? '');
    _merekCtrl = TextEditingController(text: e?.merek       ?? '');
    _hargaCtrl = TextEditingController(
      text: e != null ? e.harga.toStringAsFixed(0) : '',
    );
    _ketCtrl   = TextEditingController(text: e?.keterangan  ?? '');
    _imgCtrl   = TextEditingController();
    if (e != null) _images.addAll(e.images);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _merekCtrl.dispose();
    _hargaCtrl.dispose();
    _ketCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  void _addImage() {
    final url = _imgCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showSnack('URL gambar harus dimulai dengan http:// atau https://');
      return;
    }
    setState(() {
      _images.add(url);
      _imgCtrl.clear();
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final box = Hive.box<KoleksiModel>('koleksi');
    final harga = double.tryParse(
          _hargaCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0.0;

    if (_isEdit) {
      // Update existing
      final e         = widget.existing!;
      e.namaSepatu    = _namaCtrl.text.trim();
      e.merek         = _merekCtrl.text.trim();
      e.harga         = harga;
      e.keterangan    = _ketCtrl.text.trim();
      e.images        = List.from(_images);
      await e.save();
    } else {
      // Tambah baru
      final id = DateTime.now().millisecondsSinceEpoch.toString() +
          Random().nextInt(9999).toString();
      final koleksi = KoleksiModel(
        id: id,
        namaSepatu: _namaCtrl.text.trim(),
        merek: _merekCtrl.text.trim(),
        harga: harga,
        keterangan: _ketCtrl.text.trim(),
        images: List.from(_images),
        createdAt: DateTime.now(),
      );
      await box.put(id, koleksi);
    }

    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      _showSnack(
        _isEdit ? 'Koleksi berhasil diperbarui' : 'Koleksi berhasil ditambahkan',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Edit Koleksi' : 'Tambah Koleksi',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kTextPri,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: _kTextMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // ── Nama Sepatu ──
                    _FieldLabel('Nama Sepatu *'),
                    _FormField(
                      controller: _namaCtrl,
                      hint: 'e.g. Air Jordan 1 Retro High',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Merek ──
                    _FieldLabel('Merek *'),
                    _FormField(
                      controller: _merekCtrl,
                      hint: 'e.g. Nike, Adidas, New Balance',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Harga ──
                    _FieldLabel('Harga (Rp) *'),
                    _FormField(
                      controller: _hargaCtrl,
                      hint: 'e.g. 1500000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Keterangan ──
                    _FieldLabel('Keterangan'),
                    _FormField(
                      controller: _ketCtrl,
                      hint: 'Kondisi, ukuran, catatan...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // ── Gambar ──
                    _FieldLabel('Gambar (URL)'),
                    const SizedBox(height: 4),
                    Text(
                      'Tambahkan satu atau lebih URL gambar sepatu',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextMuted.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input URL + tombol tambah
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imgCtrl,
                            decoration: InputDecoration(
                              hintText: 'https://example.com/image.jpg',
                              hintStyle: const TextStyle(
                                color: _kTextMuted,
                                fontSize: 13,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFFF8F5),
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
                                borderSide: const BorderSide(
                                  color: _kPrimary,
                                  width: 2,
                                ),
                              ),
                            ),
                            style: const TextStyle(fontSize: 13),
                            keyboardType: TextInputType.url,
                            onFieldSubmitted: (_) => _addImage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),

                    // Daftar gambar yang sudah ditambahkan
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _images[i],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(0xFFF3F0EC),
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: _kTextMuted,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removeImage(i),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Tombol Simpan ──
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Simpan Koleksi',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Form Widgets ────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kTextPri,
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        filled: true,
        fillColor: const Color(0xFFFFF8F5),
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
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kError, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 14, color: _kTextPri),
    );
  }
}
