// lib/data/category_seed.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';

const _othersId = 0;

Future<void> seedCategoriesIfEmpty() async {
  final box = Hive.box<Category>('categories');
  if (box.isNotEmpty) return;

  final List<Map<String, dynamic>> base = [
    {'name': 'Others',        'icon': Icons.all_inclusive,  'color': Colors.grey},
    {'name': 'Work',          'icon': Icons.work,           'color': Colors.blue},
    {'name': 'Personal',      'icon': Icons.person,         'color': Colors.teal},
    {'name': 'Study',         'icon': Icons.menu_book,      'color': Colors.indigo},
    {'name': 'Health',        'icon': Icons.favorite,       'color': Colors.redAccent},
    {'name': 'Fitness',       'icon': Icons.fitness_center, 'color': Colors.green},
    {'name': 'Shopping',      'icon': Icons.shopping_bag,   'color': Colors.pink},
    {'name': 'Groceries',     'icon': Icons.local_grocery_store,'color': Colors.lightGreen},
    {'name': 'Bills',         'icon': Icons.receipt_long,   'color': Colors.orange},
    {'name': 'Finance',       'icon': Icons.account_balance,'color': Colors.brown},
    {'name': 'Travel',        'icon': Icons.flight,         'color': Colors.cyan},
    {'name': 'Home',          'icon': Icons.home,           'color': Colors.blueGrey},
    {'name': 'Errands',       'icon': Icons.directions_run, 'color': Colors.deepPurple},
    {'name': 'Calls',         'icon': Icons.call,           'color': Colors.deepOrange},
    {'name': 'Meetings',      'icon': Icons.groups,         'color': Colors.blue},
    {'name': 'Reading',       'icon': Icons.menu_book,      'color': Colors.indigoAccent},
    {'name': 'Learning',      'icon': Icons.school,         'color': Colors.amber},
    {'name': 'Projects',      'icon': Icons.folder,         'color': Colors.blue},
    {'name': 'Ideas',         'icon': Icons.lightbulb,      'color': Colors.amberAccent},
    {'name': 'Hobby',         'icon': Icons.brush,          'color': Colors.purple},
    {'name': 'Music',         'icon': Icons.music_note,     'color': Colors.deepPurple},
    {'name': 'Movies',        'icon': Icons.movie,          'color': Colors.grey},
    {'name': 'Gaming',        'icon': Icons.sports_esports, 'color': Colors.teal},
    {'name': 'Social',        'icon': Icons.people,         'color': Colors.blue},
    {'name': 'Garden',        'icon': Icons.grass,          'color': Colors.green},
    {'name': 'Car',           'icon': Icons.directions_car, 'color': Colors.blueGrey},
    {'name': 'Pets',          'icon': Icons.pets,           'color': Colors.brown},
    {'name': 'Kids',          'icon': Icons.child_care,     'color': Colors.pinkAccent},
    {'name': 'Birthday',      'icon': Icons.cake,           'color': Colors.pink},
    {'name': 'Anniversary',   'icon': Icons.favorite_border,'color': Colors.red},
    {'name': 'Cleaning',      'icon': Icons.cleaning_services,'color': Colors.lightBlue},
    {'name': 'Repairs',       'icon': Icons.build,          'color': Colors.orange},
    {'name': 'Tech',          'icon': Icons.memory,         'color': Colors.indigo},
    {'name': 'Emails',        'icon': Icons.email,          'color': Colors.cyan},
    {'name': 'Writing',       'icon': Icons.edit,           'color': Colors.amber},
    {'name': 'Design',        'icon': Icons.palette,        'color': Colors.purpleAccent},
    {'name': 'Photography',   'icon': Icons.camera_alt,     'color': Colors.blueGrey},
    {'name': 'Volunteer',     'icon': Icons.volunteer_activism,'color': Colors.green},
    {'name': 'Meditation',    'icon': Icons.self_improvement,'color': Colors.teal},
    {'name': 'Cooking',       'icon': Icons.restaurant,     'color': Colors.deepOrange},
    {'name': 'Events',        'icon': Icons.event,          'color': Colors.blue},
    {'name': 'To Review',     'icon': Icons.rate_review,    'color': Colors.brown},
    {'name': 'Wish List',     'icon': Icons.star_border,    'color': Colors.amber},
    {'name': 'Chores',        'icon': Icons.task_alt,       'color': Colors.lightGreen},
  ];

  // حمّل الأساس الأول
  final List<Category> initial = [];
  for (int i = 0; i < base.length; i++) {
    final m = base[i];
    final isOthers = i == 0;
    initial.add(
      Category(
        id: i,
        name: m['name'] as String,
        iconCodePoint: (m['icon'] as IconData).codePoint,
        iconFontFamily: (m['icon'] as IconData).fontFamily ?? 'MaterialIcons',
        color: (m['color'] as Color).value,
        isDeletable: !isOthers,
      ),
    );
  }

  // كمّل تلقائيًا لحد 100
  int nextId = initial.length;
  while (initial.length < 100) {
    initial.add(
      Category(
        id: nextId,
        name: 'Category $nextId',
        iconCodePoint: Icons.label.codePoint,
        iconFontFamily: Icons.label.fontFamily ?? 'MaterialIcons',
        color: Colors.grey.value,
        isDeletable: true,
      ),
    );
    nextId++;
  }

  // اكتبهم في البوكس
  for (final c in initial) {
    await box.put(c.id, c);
  }
}
