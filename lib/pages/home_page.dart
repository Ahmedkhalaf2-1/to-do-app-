// home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repos/category_repo.dart';

/// ===== Helpers for optional fields on Task (backward-safe) =====
bool _hasArchivedField(Task t) {
  try {
    // ignore: unused_local_variable
    final _ = (t as dynamic).archived;
    return true;
  } catch (_) {
    return false;
  }
}

bool _isArchived(Task t) {
  try {
    final v = (t as dynamic).archived;
    return v == true;
  } catch (_) {
    return false;
  }
}

/// Shared neon + dark palette (matches your other pages)
class _Palette {
  static const bg        = Color(0xFF0B0B0D);
  static const card      = Color(0xFF101114);
  static const cardSoft  = Color(0xFF141416);
  static const border    = Color(0xFF1E1E25);
  static const hint      = Color(0xFF2A2A33);

  static const primary   = Color(0xFFE6FF42); // neon yellow
  static const onPrimary = Color(0xFF0B0B0D);

  static const txt      = Colors.white;
  static const txtMuted = Colors.white70;
  static const txtDim   = Colors.white54;

  static const danger   = Color(0xFFF7768E);
  static const success  = Color(0xFF9ECE6A);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // icon, name
  static final categories = <(IconData, String)>[
    (Icons.person,                'personal'),
    (Icons.work,                  'work'),
    (Icons.sports_soccer_outlined,'sport'),
    (Icons.shopping_bag_rounded,  'Shopping'),
    (Icons.home_filled,           'home'),
  ];

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<AppUser>('user');
    final user = userBox.values.isNotEmpty ? userBox.values.first : null;

    return Scaffold(
      backgroundColor: _Palette.bg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab_unique',
        onPressed: () {
          // TODO: quick add
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _Palette.primary,
        foregroundColor: _Palette.onPrimary,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _Palette.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Palette.border),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1C1C21),
                    backgroundImage: (user?.imagePath != null)
                        ? FileImage(File(user!.imagePath!))
                        : null,
                    child: (user?.imagePath == null)
                        ? const Icon(Icons.person, color: _Palette.txtMuted, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'What are you doing today?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _Palette.txt,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _glassIcon(),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _searchBox(),

            const SizedBox(height: 16),
            const Text('Category',
                style: TextStyle(color: _Palette.txt, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            // Category cards
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final (icon, name) = categories[i];
                  return _categoryCard(context, icon, name);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Today's Tasks header card
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              decoration: BoxDecoration(
                color: _Palette.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _Palette.border),
              ),
              child: const Text(
                "Today's Tasks",
                style: TextStyle(
                  color: _Palette.txt,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _todaysTasks(context),
          ],
        ),
      ),
    );
  }

  // ---------- Small UI helpers ----------
  static Widget _glassIcon() => Container(
    height: 36,
    width: 36,
    decoration: BoxDecoration(
      color: const Color(0x191F1F23),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x332C2C35)),
    ),
    child: const Icon(Icons.tune_rounded, color: _Palette.txtMuted, size: 20),
  );

  static Widget _searchBox() => Container(
    height: 48,
    decoration: BoxDecoration(
      color: _Palette.cardSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _Palette.hint),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: const Row(
      children: [
        Icon(Icons.search_rounded, color: _Palette.txtDim, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            style: TextStyle(color: _Palette.txt),
            decoration: InputDecoration(
              hintText: 'Search tasks',
              hintStyle: TextStyle(color: _Palette.txtDim),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.filter_list_rounded, color: _Palette.txtDim, size: 20),
      ],
    ),
  );

  Widget _categoryCard(BuildContext context, IconData icon, String name, {int? categoryId}) {
    final tasksBox = Hive.box<Task>('tasks');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/category',
        arguments: name,
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x16141416), Color(0x22141416)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          color: _Palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.border),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 22, offset: Offset(0, 10))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _Palette.cardSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Palette.hint),
                  ),
                  child: Icon(icon, color: _Palette.txt, size: 22),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: _Palette.primary, shape: BoxShape.circle),
                ),
              ],
            ),
            const Spacer(),
            Text(name, style: const TextStyle(color: _Palette.txt, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),

            // 🔁 reactive count (hides archived)
            ValueListenableBuilder(
              valueListenable: tasksBox.listenable(),
              builder: (_, Box<Task> b, __) {
                final count = b.values.where((t) {
                  final byName = t.category == name;
                  final byId   = categoryId != null && t.effectiveCategoryId == categoryId;
                  final inCat  = categoryId != null ? (byName || byId) : byName;
                  return inCat && !_isArchived(t);
                }).length;
                return Text(
                  '$count ${count == 1 ? 'task' : 'tasks'}',
                  style: const TextStyle(color: _Palette.txtDim, fontSize: 12),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _todaysTasks(BuildContext context) {
    final box = Hive.box<Task>('tasks');
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final today = DateTime.now();

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (_, Box<Task> b, __) {
        // Hide archived tasks from Today
        final items = b.values
            .where((t) => sameDay(t.date, today) && !_isArchived(t))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Text('No tasks for today',
                style: TextStyle(color: _Palette.txtDim)),
          );
        }

        return Column(
          children: [
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _swipeableTaskTile(context, t),
              ),
          ],
        );
      },
    );
  }

  // Swipe right = finish; swipe left = delete/archive
  Widget _swipeableTaskTile(BuildContext context, Task t) {
    final isDone = t.status == TaskStatus.done;
    return Dismissible(
      key: ValueKey('home-${t.key}'),
      background: _swipeBg(
        alignLeft: true,
        color: _Palette.success.withOpacity(.18),
        icon: Icons.check_circle_rounded,
        label: 'Finish',
        labelColor: _Palette.success,
      ),
      secondaryBackground: _swipeBg(
        alignLeft: false,
        color: _Palette.danger.withOpacity(.18),
        icon: Icons.delete_forever_rounded,
        label: isDone ? 'Archive' : 'Delete', // dynamic label
        labelColor: _Palette.danger,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // Mark as Done (+ completedAt if available)
          await _markTaskDone(t, context);
          return false; // keep visible; user can swipe left after
        } else {
          // Left swipe
          if (isDone) {
            // Archive if the field exists
            if (_hasArchivedField(t)) {
              try {
                (t as dynamic).archived = true;
              } catch (_) {}
              await t.save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task archived (kept in Completed)')),
                );
              }
              return true; // remove from Today (archived are hidden)
            } else {
              // Fallback: move the due date to yesterday so it leaves "Today" but stays Completed
              t.date = t.date.subtract(const Duration(days: 1));
              await t.save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task kept in Completed')),
                );
              }
              return true;
            }
          } else {
            // Not done → hard delete
            await t.delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            }
            return true;
          }
        }
      },
      child: _taskTile(context, t),
    );
  }

  /// Robust "mark done" that also sets `completedAt` when available
  Future<void> _markTaskDone(Task t, BuildContext context) async {
    t.status = TaskStatus.done;
    try {
      (t as dynamic).completedAt = DateTime.now();
    } catch (_) {}
    await t.save();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as done')),
      );
    }
  }

  Widget _swipeBg({
    required bool alignLeft,
    required Color color,
    required IconData icon,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: labelColor.withOpacity(.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisAlignment:
        alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Icon(icon, color: labelColor),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: labelColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// ===== Task tile (now shows description under title) =====
  Widget _taskTile(BuildContext context, Task t) {
    final hasDesc = t.description.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => openTaskSheet(context, t),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Palette.cardSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.border),
        ),
        child: Row(
          children: [
            // Neon strip
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: _Palette.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _Palette.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _Palette.hint),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: _Palette.txtMuted, size: 20),
            ),
            const SizedBox(width: 12),

            // Title + description + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _Palette.txt,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),

                  // Description (only if not empty)
                  if (hasDesc) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Palette.txtDim,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Meta row
                  Row(
                    children: [
                      _StatusChip(statusText: _statusLabel(t.status)),
                      const SizedBox(width: 8),
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: _Palette.txtDim),
                      const SizedBox(width: 4),
                      Text(
                        '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
                        style:
                        const TextStyle(color: _Palette.txtDim, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _Palette.txtMuted),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TaskStatus s) => switch (s) {
    TaskStatus.pending    => 'Pending',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.done       => 'Done',
  };
}

/// ======= Task Details Bottom-Sheet =======
Future<void> openTaskSheet(BuildContext context, Task t) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskSheet(task: t),
  );
}

class _TaskSheet extends StatefulWidget {
  final Task task;
  const _TaskSheet({required this.task});

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> with TickerProviderStateMixin {
  late Task t;
  late TabController _tab;

  bool _picking = false;

  @override
  void initState() {
    super.initState();
    t = widget.task;
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  int get _remaining => t.checklist.values.where((v) => !v).length;
  int get _completed => t.checklist.values.where((v) => v).length;

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const w = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    return '${w[d.weekday % 7]}, ${d.day} ${m[d.month-1]}';
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final total = t.checklist.isEmpty ? 1 : t.checklist.length;
    final progress = _completed / total;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scroll) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: _Palette.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: const Color(0xFF1D1D22)),
              boxShadow: const [BoxShadow(blurRadius: 30, color: Colors.black54)],
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  height: 4, width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A31),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),

                // Title & meta row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _Palette.cardSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _Palette.border),
                      ),
                      child: Text(t.category,
                          style: const TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    _NeonTag('$_remaining remaining'),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.title,
                    style: const TextStyle(
                      color: _Palette.txt,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1C1C22),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1 ? _Palette.success : _Palette.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_completed}/${t.checklist.length} completed',
                    style: const TextStyle(color: _Palette.txtDim, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // Segmented
                Container(
                  decoration: BoxDecoration(
                    color: _Palette.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Palette.border),
                  ),
                  child: TabBar(
                    controller: _tab,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(vertical: 10),
                    indicator: BoxDecoration(
                      color: _Palette.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: _Palette.primary.withOpacity(.25), blurRadius: 18)],
                    ),
                    labelColor: _Palette.onPrimary,
                    unselectedLabelColor: _Palette.txtMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Checklist'),
                      Tab(text: 'Attachments'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _overviewTab(),
                      _checklistTab(),
                      _attachmentsTab(),
                    ],
                  ),
                ),

                // Footer actions
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _Palette.hint),
                        foregroundColor: _Palette.txtMuted,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Close'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await t.save();
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primary,
                        foregroundColor: _Palette.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Tabs ---

  Widget _overviewTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Row(
          children: [
            _kv('Assigned to', t.assignee),
            const Spacer(),
            _kv('Due Date', _fmtDate(t.date), alignEnd: true),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Status',
            style: TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _statusChoice('Pending', TaskStatus.pending, t.status),
            _statusChoice('In Progress', TaskStatus.inProgress, t.status),
            _statusChoice('Done', TaskStatus.done, t.status),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Description',
            style: TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _descriptionBox(
          initial: t.description,
          onChanged: (val) async {
            t.description = val;
            await t.save();
          },
        ),
      ],
    );
  }

  Widget _checklistTab() {
    if (t.checklist.isEmpty) {
      return const Center(
        child: Text('No steps yet',
            style: TextStyle(color: _Palette.txtDim)),
      );
    }
    return ListView(
      children: [
        const SizedBox(height: 8),
        for (final e in t.checklist.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _checkTile(
              title: e.key,
              value: e.value,
              onChanged: (v) async {
                setState(() => t.checklist[e.key] = v);
                await t.save();
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _attachmentsTab() {
    return ListView(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            _addImageButton(onPick: _addImage),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: t.imagePaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _thumb(t.imagePaths[i]),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Reusable widgets in sheet ---

  Widget _statusChoice(String label, TaskStatus value, TaskStatus group) {
    final selected = value == group;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? _Palette.onPrimary : _Palette.txtMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
      selected: selected,
      onSelected: (s) async {
        if (!s) return;
        setState(() {
          t.status = value;
          // If marked done, set completedAt when available
          if (value == TaskStatus.done) {
            try {
              (t as dynamic).completedAt = DateTime.now();
            } catch (_) {}
          }
        });
        await t.save();
      },
      selectedColor: _Palette.primary,
      backgroundColor: _Palette.cardSoft,
      side: const BorderSide(color: _Palette.hint),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _kv(String k, String v, {bool alignEnd = false}) => Column(
    crossAxisAlignment:
    alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(k, style: const TextStyle(color: _Palette.txtDim)),
      const SizedBox(height: 4),
      Text(v, style: const TextStyle(color: _Palette.txt, fontWeight: FontWeight.w700)),
    ],
  );

  Widget _descriptionBox({
    required String initial,
    required ValueChanged<String> onChanged,
  }) {
    final ctl = TextEditingController(text: initial);
    return TextField(
      controller: ctl,
      maxLines: 3,
      onChanged: onChanged,
      style: const TextStyle(color: _Palette.txt),
      decoration: InputDecoration(
        hintText: 'Write something…',
        hintStyle: const TextStyle(color: _Palette.txtDim),
        filled: true,
        fillColor: _Palette.cardSoft,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _Palette.hint),
        ),
      ),
    );
  }

  Widget _checkTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _Palette.cardSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                color: value ? _Palette.primary : Colors.transparent,
                border: Border.all(color: const Color(0xFF3A3A42)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: value
                  ? const Icon(Icons.check, size: 18, color: _Palette.onPrimary)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _Palette.txt,
                decoration: value ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String path) {
    final f = File(path);
    if (!f.existsSync()) {
      return Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: _Palette.cardSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Palette.border),
        ),
        child: const Icon(Icons.broken_image_rounded, color: _Palette.txtDim),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(f, width: 90, height: 90, fit: BoxFit.cover),
    );
  }

  Widget _addImageButton({required Future<void> Function() onPick}) => InkWell(
    onTap: onPick,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: _Palette.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: const Icon(Icons.add_a_photo_rounded, color: _Palette.txtMuted),
    ),
  );

  Future<void> _addImage() async {
    if (_picking) return;
    _picking = true;
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (img == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final safeName = '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
      final f = File('${dir.path}/$safeName');

      final bytes = await img.readAsBytes();
      await f.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() => t.imagePaths.add(f.path));
      await t.save();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add image: $e')),
        );
      }
    } finally {
      _picking = false;
    }
  }
}

class _NeonTag extends StatelessWidget {
  final String text;
  const _NeonTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Palette.cardSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Palette.hint),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _Palette.txtMuted, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String statusText;
  const _StatusChip({required this.statusText});

  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return _Palette.success;
      case 'in progress':
        return const Color(0xFF2EE6A6);
      case 'pending':
      default:
        return _Palette.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorForStatus(statusText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withOpacity(.18), c.withOpacity(.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: .25,
        ),
      ),
    );
  }

}

