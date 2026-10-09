import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';

/// Neon black + yellow palette inspired by the screenshot
class _Palette {
  static const bg = Color(0xFF0B0B0D);            // page background
  static const card = Color(0xFF101114);          // cards
  static const cardSoft = Color(0xFF141416);      // inner surfaces
  static const border = Color(0xFF1E1E25);        // borders
  static const hint = Color(0xFF2A2A33);          // subtle dividers

  // Primary accent (neon yellow/green)
  static const primary = Color(0xFFE6FF42);       // highlight pill + primary card
  static const onPrimary = Color(0xFF0B0B0D);     // text on primary

  static const txt = Colors.white;                // main text
  static const txtMuted = Colors.white70;         // secondary
  static const txtDim = Colors.white54;           // tertiary
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  CalendarFormat _format = CalendarFormat.month;

  // reusable formatters (ما نعيدش إنشائها كل مرة)
  static final DateFormat _monthTitleFmt = DateFormat.yMMMM();
  static final DateFormat _taskTimeFmt = DateFormat('hh:mma');

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _setFormat(CalendarFormat f) {
    if (_format != f) setState(() => _format = f);
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Task>('tasks');

    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        title: const Text('Task', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _Palette.bg,
        elevation: 0,
        automaticallyImplyLeading: false, // ما تضيفش Back تلقائيًا
        leading: Navigator.of(context).canPop()
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FormatToggle(
              format: _format,
              onChanged: (f) => setState(() => _format = f),
            ),
          ),
        ],
      ),
      // ⛔ تم إزالة زرار Add task كما طلبت
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, Box<Task> b, __) {
          // ---- Build events map from Hive (logic preserved) ----
          final events = <DateTime, List<Task>>{};
          for (final t in b.values) {
            final k = _normalize(t.date);
            (events[k] ??= []).add(t);
          }

          List<Task> selectedEvents() {
            final d = _selected ?? DateTime.now();
            final list = events[_normalize(d)] ?? <Task>[];
            list.sort((a, b) => a.date.compareTo(b.date));
            return list;
          }
          // ------------------------------------------------------

          final hasSelection =
              _selected != null && _isSameDay(_selected!, DateTime.now()) == false;

          return Column(
            children: [
              // Calendar Card
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _Palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _Palette.border),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TableCalendar<Task>(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2100),
                        focusedDay: _focused,
                        calendarFormat: _format,
                        selectedDayPredicate: (d) =>
                        _selected != null && _isSameDay(d, _selected!),
                        onDaySelected: (sel, foc) {
                          // ما نعملش setState لو نفس اليوم
                          final shouldUpdate = _selected == null || !_isSameDay(sel, _selected!);
                          if (shouldUpdate || !_isSameDay(foc, _focused)) {
                            setState(() {
                              _selected = sel;
                              _focused = foc;
                            });
                          }
                        },
                        onPageChanged: (foc) {
                          if (!_isSameDay(foc, _focused)) {
                            setState(() => _focused = foc);
                          }
                        },
                        eventLoader: (day) => events[_normalize(day)] ?? const <Task>[],
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextFormatter: (date, _) => _monthTitleFmt.format(date),
                          titleTextStyle: const TextStyle(
                            color: _Palette.txt,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                          leftChevronIcon: const Icon(Icons.chevron_left, color: _Palette.txtMuted),
                          rightChevronIcon: const Icon(Icons.chevron_right, color: _Palette.txtMuted),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: _Palette.txtMuted, fontSize: 12),
                          weekendStyle: TextStyle(color: _Palette.txtMuted, fontSize: 12),
                        ),
                        calendarStyle: const CalendarStyle(
                          outsideDaysVisible: false,
                          markersAlignment: Alignment.bottomCenter,
                          markersMaxCount: 3,
                          // Fallbacks (we override with builders too)
                          todayDecoration: BoxDecoration(
                            color: _Palette.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: _Palette.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(color: _Palette.onPrimary),
                          defaultTextStyle: TextStyle(color: _Palette.txt),
                          weekendTextStyle: TextStyle(color: _Palette.txt),
                          disabledTextStyle: TextStyle(color: _Palette.txtDim),
                        ),
                        calendarBuilders: CalendarBuilders<Task>(
                          // Neon selected
                          selectedBuilder: (context, date, _) => _DayCircle(
                            date: date,
                            bg: _Palette.primary,
                            fg: _Palette.onPrimary,
                          ),
                          // Make "today" also primary ring to mimic the sample
                          todayBuilder: (context, date, _) => _DayCircle(
                            date: date,
                            bg: _Palette.primary,
                            fg: _Palette.onPrimary,
                          ),
                          // Tiny colored dots below numbers (by category)
                          markerBuilder: (context, date, dayEvents) {
                            if (dayEvents.isEmpty) return const SizedBox.shrink();
                            final dots = dayEvents
                                .take(3)
                                .map((t) => _CategoryDot(
                              color: _colorForCategory(t.category),
                            ))
                                .toList();
                            return Padding(
                              padding: const EdgeInsets.only(top: 38),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: dots,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (hasSelection)
                      Positioned(
                        right: 10,
                        top: 6,
                        child: Semantics(
                          button: true,
                          label: 'Jump to today',
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _Palette.txt,
                              side: const BorderSide(color: _Palette.txtDim),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => setState(() {
                              _selected = DateTime.now();
                              _focused = DateTime.now();
                            }),
                            icon: const Icon(Icons.today, size: 18),
                            label: const Text('Today'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tasks Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  decoration: BoxDecoration(
                    color: _Palette.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _Palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TasksHeader(date: _selected ?? DateTime.now()),
                      const SizedBox(height: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: Builder(
                            builder: (_) {
                              final items = selectedEvents();
                              if (items.isEmpty) return const _EmptyTasks();
                              return ListView.separated(
                                key: ValueKey<DateTime>(
                                  _normalize(_selected ?? DateTime.now()),
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _TaskTile(
                                  task: items[i],
                                  timeFmt: _taskTimeFmt,
                                  highlight: i == 0, // first card pops (neon)
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Color helpers for categories/status (kept) ----------
  Color _colorForCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'work':
        return const Color(0xFF7AA2F7);
      case 'personal':
        return const Color(0xFFF7768E);
      case 'health':
        return const Color(0xFF9ECE6A);
      case 'study':
      case 'school':
        return const Color(0xFFB48EAD);
      case 'home':
        return const Color(0xFFE0AF68);
      default:
        return const Color(0xFF89DDFF);
    }
  }

  Color _colorForStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'done':
      case 'completed':
        return const Color(0xFF9ECE6A);
      case 'inprogress':
      case 'in_progress':
      case 'in progress':
        return const Color(0xFFE0AF68);
      case 'blocked':
      case 'overdue':
        return const Color(0xFFF7768E);
      default:
        return const Color(0xFF7AA2F7);
    }
  }
}

// ---------- UI Helpers (UI-only; core logic untouched) ----------

class _FormatToggle extends StatelessWidget {
  final CalendarFormat format;
  final ValueChanged<CalendarFormat> onChanged;
  const _FormatToggle({required this.format, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isMonth = format == CalendarFormat.month;
    return Semantics(
      label: 'Calendar view switcher',
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _Palette.hint),
        ),
        child: Row(
          children: [
            _SegmentPill(
              label: 'Month',
              selected: isMonth,
              onTap: () => onChanged(CalendarFormat.month),
            ),
            _SegmentPill(
              label: 'Week',
              selected: !isMonth,
              onTap: () => onChanged(CalendarFormat.week),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _Palette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _Palette.onPrimary : _Palette.txtMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  final DateTime date;
  const _TasksHeader({required this.date});
  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final title = isToday
        ? 'Scheduled Tasks'
        : 'Scheduled Tasks • ${DateFormat.yMMMd().format(date)}';
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
              color: _Palette.txt, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const Spacer(),
      ],
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();
  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: _Palette.txtDim, size: 44),
          const SizedBox(height: 10),
          const Text(
            'No tasks for this day',
            style: TextStyle(color: _Palette.txtMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a task to get started',
            style: TextStyle(color: _Palette.txt.withOpacity(.5)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add task'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _Palette.txt,
              side: const BorderSide(color: _Palette.txtDim),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool highlight; // make one look like the neon card in the mock
  final DateFormat timeFmt;
  const _TaskTile({
    required this.task,
    required this.timeFmt,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = highlight ? _Palette.primary : _Palette.border;
    final txt = highlight ? _Palette.onPrimary : _Palette.txt;
    final sub = highlight ? _Palette.onPrimary.withOpacity(.8) : _Palette.txtDim;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? _Palette.primary : _Palette.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          if (highlight)
            BoxShadow(
              color: _Palette.primary.withOpacity(.35),
              blurRadius: 16,
              spreadRadius: 1,
            )
        ],
      ),
      child: Row(
        children: [
          // Leading vertical bar like the mock
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: highlight ? _Palette.onPrimary : _Palette.hint,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          // Icon / category marker
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: highlight ? _Palette.onPrimary.withOpacity(.12) : _Palette.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: highlight ? _Palette.onPrimary : _Palette.hint),
            ),
            child: Icon(Icons.insert_photo_outlined,
                size: 18, color: highlight ? _Palette.onPrimary : _Palette.txtMuted),
          ),
          const SizedBox(width: 10),
          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: _Palette.txtDim),
                    const SizedBox(width: 4),
                    Text(
                      timeFmt.format(task.date),
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.folder_open, size: 16, color: _Palette.txtDim),
                    const SizedBox(width: 4),
                    Text(task.category, style: TextStyle(color: sub, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: highlight ? _Palette.onPrimary : _Palette.txtDim),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  final DateTime date;
  final Color bg, fg;
  const _DayCircle({required this.date, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '${date.day}',
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14.5),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final Color color;
  const _CategoryDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 1.5),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
