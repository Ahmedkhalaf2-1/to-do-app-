import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

bool _isDone(Task t) => t.status == TaskStatus.done;

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Task>('tasks');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Task> b, _) {
        final tasks = b.values.toList();

        final total     = tasks.length;
        final completed = tasks.where(_isDone).length;
        final missed    = tasks.where((t) => t.isOverdue).length;
        final onTime    = tasks.where((t) => _isDone(t) && !t.isOverdue).length;

        final completedPct = total == 0 ? 0.0 : completed / total;
        final missedPct    = total == 0 ? 0.0 : missed / total;
        final onTimePct    = completed == 0 ? 0.0 : onTime / math.max(1, completed);

        final activity = _lastNDaysCounts(tasks, n: 7);

        return Scaffold(
          appBar: AppBar(title: const Text('Analytics')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: total == 0
                  ? _maybeEmpty(context, total: total, child: const SizedBox.shrink())
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    _ResponsiveGrid(
                      children: [
                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _CardHeader(title: 'Total Tasks'),
                              const SizedBox(height: 12),
                              _Sparkline(values: _runningTotalSeries(tasks)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$total Tasks', style: Theme.of(context).textTheme.titleMedium),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ],
                          ),
                        ),

                        _DonutCard(
                          title: 'Completed Tasks',
                          fraction: completedPct,
                          top: '${(completedPct * 100).round()}%',
                          bottom: '$completed/$total',
                          onTap: () => Navigator.of(context).pushNamed('/completed'),
                        ),

                        _DonutCard(
                          title: 'Missed Tasks',
                          fraction: missedPct,
                          top: '${(missedPct * 100).round()}%',
                          bottom: '$missed/$total',
                          onTap: () => Navigator.of(context).pushNamed('/missed'),
                        ),

                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _CardHeader(title: 'On Time'),
                              const SizedBox(height: 12),
                              _MiniBars(values: _onTimeSeries(tasks)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$onTime Tasks', style: Theme.of(context).textTheme.titleMedium),
                                  Text('${(onTimePct * 100).round()}%',
                                      style: Theme.of(context).textTheme.labelLarge),
                                ],
                              ),
                            ],
                          ),
                        ),

                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _CardHeader(title: 'Your Activity'),
                              const SizedBox(height: 12),
                              _AreaChart(values: activity),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<double> _runningTotalSeries(List<Task> tasks) {
    final sorted = [...tasks]..sort((a, b) => a.date.compareTo(b.date));
    var acc = 0.0;
    return sorted.map((t) {
      acc += 1;
      return acc;
    }).toList(growable: false);
  }

  List<double> _onTimeSeries(List<Task> tasks) {
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i));
      return d;
    });

    final counts = List<double>.filled(7, 0);
    for (final t in tasks) {
      final isOnTime = _isDone(t) && !t.isOverdue;
      if (!isOnTime) continue;

      final k = t.dayKey;
      final idx = days.indexWhere((d) => d.year == k.year && d.month == k.month && d.day == k.day);
      if (idx != -1) counts[idx] += 1;
    }
    return counts;
  }

  List<double> _lastNDaysCounts(List<Task> tasks, {int n = 7}) {
    final today = DateTime.now();
    final days = List.generate(n, (i) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: n - 1 - i));
      return d;
    });

    final counts = List<double>.filled(n, 0);
    for (final t in tasks.where(_isDone)) {
      final k = t.dayKey;
      final idx = days.indexWhere((d) => d.year == k.year && d.month == k.month && d.day == k.day);
      if (idx != -1) counts[idx] += 1;
    }
    return counts;
  }
}

/* ===== UI bits (unchanged from your style) ===== */

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveGrid({required this.children});

  int _colsForWidth(double w) {
    if (w >= 1100) return 3;
    if (w >= 700) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = _colsForWidth(c.maxWidth);
      const gap = 12.0;
      final itemW = (c.maxWidth - (gap * (cols - 1))) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children.map((w) => SizedBox(width: itemW, child: w)).toList(),
      );
    });
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CardContainer({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface.withOpacity(0.6);
    final border = theme.colorScheme.onSurface.withOpacity(0.06);

    final core = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );

    if (onTap == null) return core;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: theme.colorScheme.primary.withOpacity(0.08),
      child: core,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMenu;
  const _CardHeader({required this.title, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
        if (onMenu != null)
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_horiz),
            onPressed: onMenu,
          ),
      ],
    );
  }
}

class _DonutCard extends StatelessWidget {
  final String title;
  final double fraction;
  final String top;
  final String bottom;
  final VoidCallback? onTap;
  const _DonutCard({
    required this.title,
    required this.fraction,
    required this.top,
    required this.bottom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title),
          const SizedBox(height: 8),
          Center(
            child: _AnimatedDonut(
              fraction: fraction.clamp(0.0, 1.0),
              size: 120,
              labelTop: top,
              labelBottom: bottom,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onTap, child: const Text('Details')),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDonut extends StatelessWidget {
  final double fraction; // 0..1
  final double size;
  final String labelTop;
  final String labelBottom;
  const _AnimatedDonut({
    required this.fraction,
    required this.size,
    required this.labelTop,
    required this.labelBottom,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: fraction),
      builder: (context, anim, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(fraction: anim, color: primary),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      labelTop,
                      key: ValueKey(labelTop),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labelBottom, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _DonutPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.10;
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = math.min(size.width, size.height) / 2 - stroke;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.15);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(Rect.fromCircle(center: center, radius: r), math.pi * 0.75, math.pi * 1.5, false, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), math.pi * 0.75, math.pi * 1.5 * fraction, false, fg);

    final angle = math.pi * 0.75 + math.pi * 1.5 * fraction;
    final knobCenter = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
    final knob = Paint()..color = color;
    canvas.drawCircle(knobCenter, stroke * 0.35, knob);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.fraction != fraction || old.color != color;
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  const _Sparkline({required this.values});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: _SparklinePainter(values: values),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final bg = Paint()..color = Colors.white.withOpacity(0.06);
    final primary = Paint()..color = Colors.white.withOpacity(0.18);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.9);

    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    canvas.drawRRect(r, bg);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height * (1 - ((values[i] - minV) / range));
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, primary);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.values != values;
}

class _MiniBars extends StatelessWidget {
  final List<double> values;
  const _MiniBars({required this.values});
  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 0 : values.reduce(math.max);
    final safeMax = max <= 0 ? 1 : max;
    final days = _weekdayShortLabels(context);

    return Column(
      children: [
        SizedBox(
          height: 76,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(values.length, (i) {
              final v = values[i];
              final h = 12 + (v / safeMax) * 56;
              return Container(
                width: 10,
                height: h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((d) => Text(d, style: Theme.of(context).textTheme.labelSmall)).toList(),
        ),
      ],
    );
  }

  List<String> _weekdayShortLabels(BuildContext context) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final loc = MaterialLocalizations.of(context);
    return List.generate(7, (i) {
      final d = base.subtract(Duration(days: 6 - i));
      return loc.narrowWeekdays[d.weekday % 7];
    });
  }
}

class _AreaChart extends StatelessWidget {
  final List<double> values;
  const _AreaChart({required this.values});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _AreaChartPainter(values: values, color: Theme.of(context).colorScheme.primary),
        size: Size.infinite,
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _AreaChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max);
    final range = maxV == 0 ? 1.0 : maxV;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.08);
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final base = size.height * 0.85;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = base - (values[i] / range) * (base - 20);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()..color = color.withOpacity(0.22);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter old) => old.values != values || old.color != color;
}

Widget _maybeEmpty(BuildContext context, {required int total, required Widget child}) {
  if (total > 0) return child;
  final t = Theme.of(context).textTheme;
  return _CardContainer(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.insights, size: 40, color: Colors.white.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('No data yet', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Complete a few tasks to unlock your analytics.',
            style: t.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
