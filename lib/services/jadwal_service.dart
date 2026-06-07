// =============================================================================
// jadwal_service.dart
// Service CRUD untuk JadwalModel menggunakan Hive.
// =============================================================================

import 'package:hive_flutter/hive_flutter.dart';
import '../models/jadwal_model.dart';

class JadwalService {
  static const String _boxName = 'jadwal';

  Box<JadwalModel> get _box => Hive.box<JadwalModel>(_boxName);

  /// Tambah jadwal baru.
  Future<void> tambahJadwal(JadwalModel jadwal) async {
    await _box.put(jadwal.id, jadwal);
  }

  /// Ambil semua jadwal, diurutkan berdasarkan tanggal (terbaru dulu).
  List<JadwalModel> getAllJadwal() {
    final list = _box.values.toList();
    list.sort((a, b) => a.tanggalWaktu.compareTo(b.tanggalWaktu));
    return list;
  }

  /// Hapus jadwal berdasarkan ID.
  Future<void> hapusJadwal(String id) async {
    await _box.delete(id);
  }

  /// Update jadwal yang sudah ada.
  Future<void> updateJadwal(JadwalModel jadwal) async {
    await _box.put(jadwal.id, jadwal);
  }

  /// Stream untuk listen perubahan box.
  Stream<BoxEvent> watchJadwal() => _box.watch();
}
