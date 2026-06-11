// =============================================================================
// database_helper.dart
// Singleton helper untuk inisialisasi & akses SQLite via sqflite.
//
// Skema tabel:
//   users       : id (PK autoincrement), username, email, encryptedPassword
//   fingerprints: id (PK autoincrement), userId (FK→users.id), label, addedAt
//   jadwal      : id TEXT (PK), userId (FK→users.id), namaSepatu, merekSepatu,
//                 tanggalWaktu, keterangan, createdAt
//   koleksi     : id TEXT (PK), userId (FK→users.id), namaSepatu, merek,
//                 harga, keterangan, images (JSON), createdAt
// =============================================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'raksneaker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel users
    await db.execute('''
      CREATE TABLE users (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        username         TEXT    NOT NULL UNIQUE,
        email            TEXT    NOT NULL UNIQUE,
        encryptedPassword TEXT   NOT NULL
      )
    ''');

    // Tabel fingerprints — relasi ke users.id
    await db.execute('''
      CREATE TABLE fingerprints (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        userId  INTEGER NOT NULL,
        label   TEXT    NOT NULL,
        addedAt TEXT    NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabel jadwal — relasi ke users.id
    await db.execute('''
      CREATE TABLE jadwal (
        id           TEXT    PRIMARY KEY,
        userId       INTEGER NOT NULL,
        namaSepatu   TEXT    NOT NULL,
        merekSepatu  TEXT    NOT NULL,
        tanggalWaktu TEXT    NOT NULL,
        keterangan   TEXT    NOT NULL,
        createdAt    TEXT    NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabel koleksi — relasi ke users.id
    await db.execute('''
      CREATE TABLE koleksi (
        id         TEXT    PRIMARY KEY,
        userId     INTEGER NOT NULL,
        namaSepatu TEXT    NOT NULL,
        merek      TEXT    NOT NULL,
        harga      REAL    NOT NULL,
        keterangan TEXT    NOT NULL,
        images     TEXT    NOT NULL,
        createdAt  TEXT    NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }
}
