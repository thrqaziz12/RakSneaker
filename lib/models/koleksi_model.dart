// =============================================================================
// koleksi_model.dart
// Model data koleksi sepatu milik user.
// Disimpan menggunakan Hive (typeId: 3)
// Fields: id, namaSepatu, merek, harga, keterangan, images (List<String>)
// =============================================================================

import 'package:hive/hive.dart';

part 'koleksi_model.g.dart';

@HiveType(typeId: 3)
class KoleksiModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String namaSepatu;

  @HiveField(2)
  late String merek;

  @HiveField(3)
  late double harga;

  @HiveField(4)
  late String keterangan;

  /// Daftar URL/path gambar — boleh lebih dari satu
  @HiveField(5)
  late List<String> images;

  @HiveField(6)
  late DateTime createdAt;

  KoleksiModel({
    required this.id,
    required this.namaSepatu,
    required this.merek,
    required this.harga,
    required this.keterangan,
    required this.images,
    required this.createdAt,
  });
}
