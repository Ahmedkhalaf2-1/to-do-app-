// category_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../services/notification_service.dart'; // ⬅️ notifications

class _Palette {
  static const bg        = Color(0xFF0B0B0D);
  static const card      = Color(0xFF101114);
  static const cardSoft  = Color(0xFF141416);
  static const border    = Color(0xFF1E1E25);
  static const hint      = Color(0xFF2A2A33);

  static const primary   = Color(0xFFE6FF42);
  static const onPrimary = Color(0xFF0B0B0D);

  static const txt      = Colors.white;
  static const txtMuted = Colors.white70;
  static const txtDim   = Colors.white54;

  static const danger   = Color(0xFFF7768E);
  static const success  = Color(0xFF9ECE6A);
  static const inProg   = Color(0xFF2EE6A6);
}

class CategoryPage extends StatelessWidget {
  final String category;
  final int? categoryId;

  const CategoryPage({
    super.key,
    required this.category,
    this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Task>('tasks');

    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: _Palette.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            _CategoryDot(color: _Palette.primary),
            const SizedBox(width: 8),
            Text(category, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'category_fab',
        onPressed: () => _openCreateTask(context, category, categoryId),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _Palette.primary,
        foregroundColor: _Palette.onPrimary,
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (_, Box<Task> b, __) {
            final items = b.values.where((t) {
              final inCat = categoryId != null
                  ? (t.category == category || t.effectiveCategoryId == categoryId)
                  : (t.category == category);
              return inCat && !t.archived; // hide archived
            }).toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            if (items.isEmpty) return const _EmptyState();

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => Dismissible(
                key: ValueKey('cat-${items[i].key}'),
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
                  label: 'Delete',
                  labelColor: _Palette.danger,
                ),
                confirmDismiss: (dir) async {
                  final t = items[i];
                  try {
                    if (dir == DismissDirection.startToEnd) {
                      // Finish (keep visible)
                      t.status = TaskStatus.done;
                      await t.save();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task marked as done')),
                      );
                      return false;
                    } else {
                      // "Delete" → archive + mark done (kept in Completed/Analytics)
                      t.status = TaskStatus.done;
                      t.archived = true;
                      await t.save();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task archived (kept in Completed)')),
                      );
                      return true;
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Operation failed: $e')),
                    );
                    return false;
                  }
                },
                child: _TaskTile(task: items[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  // -------- create sheet (with Reminder controls) --------
  Future<void> _openCreateTask(BuildContext context, String category, int? categoryId) async {
    final formKey = GlobalKey<FormState>();
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();

    DateTime date = DateTime.now().add(const Duration(minutes: 6)); // default due ~soon
    bool useCustomReminder = false;
    DateTime reminder = date.subtract(const Duration(minutes: 5));

    void _recomputeDefaultReminder(StateSetter setSt) {
      if (!useCustomReminder) {
        reminder = date.subtract(const Duration(minutes: 5));
      }
      // never schedule in the past
      final safeMin = DateTime.now().add(const Duration(seconds: 10));
      if (reminder.isBefore(safeMin)) {
        reminder = safeMin;
      }
      setSt(() {}); // refresh tiles
    }

    bool creating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: ctx,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: date,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: _Palette.primary,
                      surface: _Palette.card,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                date = DateTime(picked.year, picked.month, picked.day, date.hour, date.minute);
                _recomputeDefaultReminder(setSt);
              }
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay(hour: date.hour, minute: date.minute),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: _Palette.primary,
                      surface: _Palette.card,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                date = DateTime(date.year, date.month, date.day, picked.hour, picked.minute);
                _recomputeDefaultReminder(setSt);
              }
            }

            Future<void> pickReminderDate() async {
              if (!useCustomReminder) return;
              final picked = await showDatePicker(
                context: ctx,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: reminder,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: _Palette.primary,
                      surface: _Palette.card,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                reminder = DateTime(picked.year, picked.month, picked.day, reminder.hour, reminder.minute);
                setSt(() {});
              }
            }

            Future<void> pickReminderTime() async {
              if (!useCustomReminder) return;
              final picked = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: _Palette.primary,
                      surface: _Palette.card,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                reminder = DateTime(reminder.year, reminder.month, reminder.day, picked.hour, picked.minute);
                setSt(() {});
              }
            }

            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              child: Container(
                decoration: BoxDecoration(
                  color: _Palette.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: _Palette.border),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 26)],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _Palette.primary.withOpacity(.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add_task, color: _Palette.txtMuted),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Create Task',
                                  style: TextStyle(color: _Palette.txt, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close_rounded, color: _Palette.txtMuted),
                              )
                            ],
                          ),
                        ),

                        // form
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            physics: const BouncingScrollPhysics(),
                            child: Form(
                              key: formKey,
                              child: Column(
                                children: [
                                  _LabeledField(
                                    label: 'Title',
                                    child: TextFormField(
                                      controller: titleCtl,
                                      autofocus: true,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(color: _Palette.txt),
                                      decoration: _dec('Enter title (required)'),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                                      maxLength: 80,
                                      buildCounter: (_, {required currentLength, maxLength, required isFocused}) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _LabeledField(
                                    label: 'Description',
                                    child: TextFormField(
                                      controller: descCtl,
                                      maxLines: 4,
                                      style: const TextStyle(color: _Palette.txt),
                                      decoration: _dec('More details (optional)'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Due date & time
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _PickerTile(
                                        icon: Icons.event_rounded,
                                        label: 'Date',
                                        value: _ymd(date),
                                        onPressed: pickDate,
                                      ),
                                      _PickerTile(
                                        icon: Icons.schedule_rounded,
                                        label: 'Time',
                                        value: _hm(date),
                                        onPressed: pickTime,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  const Divider(color: _Palette.hint),
                                  const SizedBox(height: 8),

                                  // Reminder section
                                  Row(
                                    children: const [
                                      Icon(Icons.notifications_active_rounded, color: _Palette.txtMuted),
                                      SizedBox(width: 8),
                                      Text('Reminder', style: TextStyle(color: _Palette.txt, fontWeight: FontWeight.w800)),
                                      Spacer(),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Switch for custom reminder
                                  SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    value: useCustomReminder,
                                    onChanged: (v) {
                                      useCustomReminder = v;
                                      _recomputeDefaultReminder(setSt);
                                    },
                                    title: Text(
                                      useCustomReminder
                                          ? 'Use custom reminder time'
                                          : 'Default: 5 minutes before',
                                      style: const TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w600),
                                    ),
                                    inactiveThumbColor: _Palette.primary,
                                  ),

                                  const SizedBox(height: 6),

                                  // Reminder pickers (enabled only if custom)
                                  Opacity(
                                    opacity: useCustomReminder ? 1 : .65,
                                    child: IgnorePointer(
                                      ignoring: !useCustomReminder,
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _PickerTile(
                                            icon: Icons.event_available_rounded,
                                            label: 'Reminder Date',
                                            value: _ymd(reminder),
                                            onPressed: pickReminderDate,
                                          ),
                                          _PickerTile(
                                            icon: Icons.alarm_rounded,
                                            label: 'Reminder Time',
                                            value: _hm(reminder),
                                            onPressed: pickReminderTime,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // actions
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                          child: Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _Palette.hint),
                                  foregroundColor: _Palette.txtMuted,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (creating) return;
                                    if (!formKey.currentState!.validate()) return;
                                    creating = true;
                                    try {
                                      // Create task
                                      final box = Hive.box<Task>('tasks');
                                      final task = Task(
                                        title: titleCtl.text.trim(),
                                        category: category,
                                        categoryId: categoryId ?? 0,
                                        date: date,
                                        description: descCtl.text.trim(),
                                        assignee: 'You',
                                        checklist: const {
                                          'Task step 1': false,
                                          'Task step 2': false,
                                          'Task step 3': false,
                                        },
                                      );

                                      // ⬅️ خُد الـ ID من add مباشرة (وده هو notifId الثابت)
                                      final int notifId = await box.add(task);

                                      // Decide reminder time
                                      DateTime when = useCustomReminder
                                          ? reminder
                                          : date.subtract(const Duration(minutes: 5));

                                      // safety: never in the past
                                      final safeMin = DateTime.now().add(const Duration(seconds: 10));
                                      if (when.isBefore(safeMin)) {
                                        when = safeMin;
                                      }

                                      // Schedule notification
                                      await NotificationService.scheduleAt(
                                        id: notifId,
                                        title: 'Task Reminder',
                                        body: task.title,
                                        when: when, // محلي — هيتحوّل لـ UTC جوّا الخدمة
                                      );

                                      // feedback + close
                                      if (context.mounted) {
                                        final hh = when.hour.toString().padLeft(2, '0');
                                        final mm = when.minute.toString().padLeft(2, '0');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Reminder scheduled at $hh:$mm')),
                                        );
                                        Navigator.pop(ctx);
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(content: Text('Could not create task: $e')),
                                        );
                                      }
                                    } finally {
                                      creating = false;
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _Palette.primary,
                                    foregroundColor: _Palette.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----- helpers -----
  static Widget _swipeBg({
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
        mainAxisAlignment: alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Icon(icon, color: labelColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _Palette.txtDim),
    filled: true,
    fillColor: _Palette.cardSoft,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _Palette.hint),
    ),
  );

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ------------------- UI Widgets -------------------

class _TaskTile extends StatelessWidget {
  final Task task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final dateText = '${task.date.year}-${task.date.month.toString().padLeft(2, '0')}-${task.date.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.cardSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 44, decoration: BoxDecoration(color: _Palette.primary, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _Palette.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Palette.hint),
            ),
            child: const Icon(Icons.task_alt_rounded, color: _Palette.txtMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _Palette.txt, fontWeight: FontWeight.w800, height: 1.15),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.event_rounded, size: 16, color: _Palette.txtDim),
                    const SizedBox(width: 4),
                    Text(dateText, style: const TextStyle(color: _Palette.txtDim, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.person_rounded, size: 16, color: _Palette.txtDim),
                    const SizedBox(width: 4),
                    Text(task.assignee, style: const TextStyle(color: _Palette.txtDim, fontSize: 12)),
                    const SizedBox(width: 10),
                    _StatusChip(statusText: _statusLabel(task.status)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: _Palette.txtMuted),
        ],
      ),
    );
  }

  String _statusLabel(TaskStatus s) => switch (s) {
    TaskStatus.pending    => 'Pending',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.done       => 'Done',
  };
}

class _StatusChip extends StatelessWidget {
  final String statusText;
  const _StatusChip({required this.statusText});

  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'done': return _Palette.success;
      case 'in progress': return _Palette.inProg;
      case 'pending': default: return _Palette.primary;
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Text(statusText, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: .25)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox_outlined, color: _Palette.txtDim, size: 48),
            SizedBox(height: 12),
            Text('No tasks in this category', style: TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Tap "New Task" to add one', style: TextStyle(color: _Palette.txtDim)),
          ],
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final Color color;
  const _CategoryDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({super.key, required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;
  const _PickerTile({required this.icon, required this.label, required this.value, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Palette.cardSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: _Palette.txtDim),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(value, style: const TextStyle(color: _Palette.txt, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.edit_calendar_rounded, color: _Palette.txtMuted, size: 18),
              label: const Text('Pick', style: TextStyle(color: _Palette.txtMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
  