// =============================================================================
// fingerprint_model.dart
// Model data sidik jari — disimpan di tabel SQLite 'fingerprints'.
// Setiap record terhubung ke user melalui userId.
// =============================================================================

class FingerprintModel {
  final int? id;
  final int userId;
  final String label;
  final String addedAt;

  FingerprintModel({
    this.id,
    required this.userId,
    required this.label,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'label': label,
        'addedAt': addedAt,
      };

  factory FingerprintModel.fromMap(Map<String, dynamic> map) => FingerprintModel(
        id: map['id'] as int?,
        userId: map['userId'] as int,
        label: map['label'] as String,
        addedAt: map['addedAt'] as String,
      );
}
