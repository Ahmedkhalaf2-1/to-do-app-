import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class MissedTasksPage extends StatelessWidget {
  const MissedTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Task>('tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missed Tasks'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Task> b, _) {
          final tasks = b.values.where((t) => t.isOverdue).toList()
            ..sort((a, b) => b.date.compareTo(a.date)); // newest first

          if (tasks.isEmpty) {
            return _EmptyList(
              icon: Icons.warning_amber_rounded,
              title: 'No missed tasks 🎉',
              subtitle: 'Great job! Keep it up.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final t = tasks[i];
              final dateText = MaterialLocalizations.of(context).formatMediumDate(t.date);
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Theme.of(context).colorScheme.surface.withOpacity(0.06),
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                title: Text(t.title),
                subtitle: Text('Due $dateText • missed'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: navigate to task details if you have a details page
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: tasks.length,
          );
        },
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyList({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(title, style: t.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: t.bodySmall?.copyWith(color: Colors.white70), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
