// =============================================================================
// jadwal_model.dart
// Model data jadwal perawatan sepatu — disimpan di tabel SQLite 'jadwal'.
// Setiap record terhubung ke user melalui userId.
// =============================================================================

class JadwalModel {
  final String id;
  final int userId;
  final String namaSepatu;
  final String merekSepatu;
  final DateTime tanggalWaktu;
  final String keterangan;
  final DateTime createdAt;

  JadwalModel({
    required this.id,
    required this.userId,
    required this.namaSepatu,
    required this.merekSepatu,
    required this.tanggalWaktu,
    required this.keterangan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'namaSepatu': namaSepatu,
        'merekSepatu': merekSepatu,
        'tanggalWaktu': tanggalWaktu.toIso8601String(),
        'keterangan': keterangan,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JadwalModel.fromMap(Map<String, dynamic> map) => JadwalModel(
        id: map['id'] as String,
        userId: map['userId'] as int,
        namaSepatu: map['namaSepatu'] as String,
        merekSepatu: map['merekSepatu'] as String,
        tanggalWaktu: DateTime.parse(map['tanggalWaktu'] as String),
        keterangan: map['keterangan'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
