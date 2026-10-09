// lib/models/category.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2) // اختار رقم typeId فاضي عندك
class Category extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCodePoint;

  @HiveField(3)
  String iconFontFamily;

  @HiveField(4)
  int color; // ARGB

  @HiveField(5)
  bool isDeletable;

  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
    required this.color,
    this.isDeletable = true,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);
  Color get colorObj => Color(color);
}
