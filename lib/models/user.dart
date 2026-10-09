import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
class AppUser extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) String? imagePath;
  AppUser({required this.name, this.imagePath});
}
