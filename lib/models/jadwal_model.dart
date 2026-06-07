// =============================================================================
// jadwal_model.dart
// Model data untuk jadwal perawatan sepatu.
// Disimpan menggunakan Hive (typeId: 2)
// =============================================================================

import 'package:hive/hive.dart';

part 'jadwal_model.g.dart';

@HiveType(typeId: 2)
class JadwalModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String namaSepatu;

  @HiveField(2)
  late String merekSepatu;

  @HiveField(3)
  late DateTime tanggalWaktu; // Gabungan tanggal + waktu

  @HiveField(4)
  late String keterangan;

  @HiveField(5)
  late DateTime createdAt;

  JadwalModel({
    required this.id,
    required this.namaSepatu,
    required this.merekSepatu,
    required this.tanggalWaktu,
    required this.keterangan,
    required this.createdAt,
  });
}
