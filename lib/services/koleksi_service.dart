// =============================================================================
// koleksi_service.dart
// Service CRUD untuk KoleksiModel menggunakan SQLite.
// Semua query difilter berdasarkan userId sehingga koleksi tiap user
// benar-benar terpisah.
// =============================================================================

import 'package:sqflite/sqflite.dart';
import '../core/database_helper.dart';
import '../models/koleksi_model.dart';

class KoleksiService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  /// Tambah item koleksi baru milik [userId].
  Future<void> tambahKoleksi(KoleksiModel koleksi) async {
    final db = await _db;
    await db.insert('koleksi', koleksi.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Ambil semua koleksi milik [userId], diurutkan terbaru dulu.
  Future<List<KoleksiModel>> getAllKoleksi(int userId) async {
    final db = await _db;
    final rows = await db.query(
      'koleksi',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(KoleksiModel.fromMap).toList();
  }

  /// Update koleksi (berdasarkan id dan userId).
  Future<void> updateKoleksi(KoleksiModel koleksi) async {
    final db = await _db;
    await db.update(
      'koleksi',
      koleksi.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [koleksi.id, koleksi.userId],
    );
  }

  /// Hapus item koleksi berdasarkan id dan pastikan milik [userId].
  Future<void> hapusKoleksi(String id, int userId) async {
    final db = await _db;
    await db.delete(
      'koleksi',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }
}
