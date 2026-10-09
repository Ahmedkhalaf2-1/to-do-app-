import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';
import '../models/task.dart';

class CategoryRepo {
  Box<Category> get _catBox => Hive.box<Category>('categories');
  Box<Task> get _taskBox => Hive.box<Task>('tasks');

  /// next numeric id (0 reserved for Others)
  int _nextId() {
    if (_catBox.isEmpty) return 1;
    final ids = _catBox.values.map((e) => e.id).toList()..sort();
    var n = 1;
    for (final id in ids) {
      if (id == n) n++; else if (id > n) break;
    }
    return n;
  }

  Future<Category> add({
    required String name,
    required IconData icon,
    required Color color,
    bool deletable = true,
  }) async {
    // unique name guard (case-insensitive)
    final exists = _catBox.values.any((c) => c.name.toLowerCase() == name.toLowerCase());
    if (exists) {
      throw Exception('Category with the same name already exists');
    }

    final c = Category(
      id: _nextId(),
      name: name,
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily ?? 'MaterialIcons',
      color: color.value,
      isDeletable: deletable,
    );

    await _catBox.put(c.id, c);
    return c;
  }

  /// Delete category by id and move its tasks to "Others"
  Future<void> delete(int id) async {
    final cat = _catBox.get(id);
    if (cat == null) return;
    if (!cat.isDeletable) {
      throw Exception('This category cannot be deleted');
    }

    // ensure "Others" exists (id=0)
    final others = _catBox.get(0);
    if (others == null) {
      await _catBox.put(
        0,
        Category(
          id: 0,
          name: 'Others',
          iconCodePoint: Icons.all_inclusive.codePoint,
          iconFontFamily: Icons.all_inclusive.fontFamily ?? 'MaterialIcons',
          color: Colors.grey.value,
          isDeletable: false,
        ),
      );
    }

    // move tasks pointing to this category (by name match)
    final catName = cat.name;
    for (final t in _taskBox.values) {
      if (t.category == catName) {
        t.category = 'Others';
        await t.save();
      }
    }

    await _catBox.delete(id);
  }

  List<Category> all() => _catBox.values.toList()..sort((a,b)=>a.id.compareTo(b.id));
}
