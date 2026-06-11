// =============================================================================
// koleksi_model.dart
// Model data koleksi sepatu — disimpan di tabel SQLite 'koleksi'.
// Setiap record terhubung ke user melalui userId.
// Field 'images' disimpan sebagai JSON string (List<String>).
// =============================================================================

import 'dart:convert';

class KoleksiModel {
  final String id;
  final int userId;
  final String namaSepatu;
  final String merek;
  final double harga;
  final String keterangan;
  final List<String> images;
  final DateTime createdAt;

  KoleksiModel({
    required this.id,
    required this.userId,
    required this.namaSepatu,
    required this.merek,
    required this.harga,
    required this.keterangan,
    required this.images,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'namaSepatu': namaSepatu,
        'merek': merek,
        'harga': harga,
        'keterangan': keterangan,
        'images': jsonEncode(images),
        'createdAt': createdAt.toIso8601String(),
      };

  factory KoleksiModel.fromMap(Map<String, dynamic> map) => KoleksiModel(
        id: map['id'] as String,
        userId: map['userId'] as int,
        namaSepatu: map['namaSepatu'] as String,
        merek: map['merek'] as String,
        harga: (map['harga'] as num).toDouble(),
        keterangan: map['keterangan'] as String,
        images: List<String>.from(
            jsonDecode(map['images'] as String) as List),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
