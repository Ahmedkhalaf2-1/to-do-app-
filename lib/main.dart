import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'models/task.dart';
import 'models/user.dart';

import 'pages/welcome_page.dart';
import 'pages/home_page.dart';
import 'pages/calendar_page.dart';
import 'pages/category_page.dart';
import 'pages/analytics_page.dart';
import 'pages/completed_tasks_page.dart';   // ✅
import 'pages/missed_tasks_page.dart';      // ✅

import 'services/notification_service.dart'; // ✅ notifications

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(AppUserAdapter());
  await Hive.openBox<AppUser>('user');
  await Hive.openBox<Task>('tasks');

  // 🔔 Local notifications (timezone + permission)
  await NotificationService.init();

  runApp(const ToDoApp());
}

/// Global dark + neon palette
class AppPalette {
  static const bg        = Color(0xFF0B0B0D);
  static const card      = Color(0xFF101114);
  static const cardSoft  = Color(0xFF141416);
  static const border    = Color(0xFF1E1E25);
  static const hint      = Color(0xFF2A2A33);

  static const primary   = Color(0xFFE6FF42);
  static const onPrimary = Color(0xFF0B0B0D);

  static const txt       = Colors.white;
  static const txtMuted  = Colors.white70;
  static const txtDim    = Colors.white54;
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUser = Hive.box<AppUser>('user').isNotEmpty;

    final scheme = const ColorScheme.dark(
      primary: AppPalette.primary,
      surface: AppPalette.card,
      onSurface: AppPalette.txt,
      background: AppPalette.bg,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo Hive',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppPalette.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppPalette.bg,
          foregroundColor: AppPalette.txt,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppPalette.txtMuted),
          titleMedium: TextStyle(color: AppPalette.txt, fontWeight: FontWeight.w700),
        ),
      ),
      initialRoute: hasUser ? '/shell' : '/welcome',
      routes: {
        '/welcome'  : (_) => const WelcomePage(),
        '/shell'    : (_) => const _Shell(),
        '/category' : (ctx) {
          final String name = ModalRoute.of(ctx)!.settings.arguments as String;
          return CategoryPage(category: name);
        },
        '/analytics': (_) => const AnalyticsPage(),

        // ✅ These match the Analytics tiles / direct navigation
        '/completed': (_) => const CompletedTasksPage(),
        '/missed'   : (_) => const MissedTasksPage(),
      },
    );
  }
}

/// Bottom navigation shell
class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  final _pages = const [
    HomePage(key: PageStorageKey('home')),
    CalendarPage(key: PageStorageKey('calendar')),
    AnalyticsPage(key: PageStorageKey('analytics')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppPalette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.border),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 22, offset: Offset(0, 8)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SalomonBottomBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              backgroundColor: Colors.transparent,
              selectedItemColor: AppPalette.primary,
              unselectedItemColor: AppPalette.txtMuted,
              itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.home_rounded),
                  title: const Text('Home'),
                  selectedColor: AppPalette.primary,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Calendar'),
                  selectedColor: AppPalette.primary,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.query_stats_rounded),
                  title: const Text('Analytics'),
                  selectedColor: AppPalette.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
