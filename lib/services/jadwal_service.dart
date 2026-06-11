// =============================================================================
// jadwal_service.dart
// Service CRUD untuk JadwalModel menggunakan SQLite.
// Semua query difilter berdasarkan userId sehingga data jadwal tiap user
// benar-benar terpisah.
// =============================================================================

import 'package:sqflite/sqflite.dart';
import '../core/database_helper.dart';
import '../models/jadwal_model.dart';

class JadwalService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  /// Tambah jadwal baru milik [userId].
  Future<void> tambahJadwal(JadwalModel jadwal) async {
    final db = await _db;
    await db.insert('jadwal', jadwal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Ambil semua jadwal milik [userId], diurutkan berdasarkan tanggal.
  Future<List<JadwalModel>> getAllJadwal(int userId) async {
    final db = await _db;
    final rows = await db.query(
      'jadwal',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'tanggalWaktu ASC',
    );
    return rows.map(JadwalModel.fromMap).toList();
  }

  /// Update jadwal yang sudah ada (berdasarkan id dan userId).
  Future<void> updateJadwal(JadwalModel jadwal) async {
    final db = await _db;
    await db.update(
      'jadwal',
      jadwal.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [jadwal.id, jadwal.userId],
    );
  }

  /// Hapus jadwal berdasarkan id dan pastikan milik [userId].
  Future<void> hapusJadwal(String id, int userId) async {
    final db = await _db;
    await db.delete(
      'jadwal',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }
}
