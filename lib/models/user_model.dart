import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  late String username;

  @HiveField(1)
  late String email;

  @HiveField(2)
  late String encryptedPassword;

  UserModel({
    required this.username,
    required this.email,
    required this.encryptedPassword,
  });
}
