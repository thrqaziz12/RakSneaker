import 'package:hive/hive.dart';

part 'fingerprint_model.g.dart';

@HiveType(typeId: 1)
class FingerprintModel extends HiveObject {
  @HiveField(0)
  late String username;

  @HiveField(1)
  late String label;

  @HiveField(2)
  late String addedAt;

  FingerprintModel({
    required this.username,
    required this.label,
    required this.addedAt,
  });
}
