import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Generative neon wallpaper that matches your app palette.
/// Non-solid: layered mesh gradients, soft glows, grain, and subtle diagonal strokes.
class NeonWallpaper extends StatelessWidget {
  const NeonWallpaper({
    super.key,
    this.bgColor = const Color(0xFF0B0B0D),
    this.primary = const Color(0xFFE6FF42),
    this.seed,
    this.intensity = 1.0, // 0.6 .. 1.4 looks nice
    this.grainOpacity = 0.035,
    this.showDiagonalStrokes = true,
  });

  final Color bgColor;
  final Color primary;
  final int? seed;
  final double intensity;
  final double grainOpacity;
  final bool showDiagonalStrokes;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _NeonWallpaperPainter(
          bgColor: bgColor,
          primary: primary,
          seed: seed,
          k: intensity.clamp(0.5, 1.5),
          grainOpacity: grainOpacity.clamp(0.0, 0.12),
          showDiagonalStrokes: showDiagonalStrokes,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _NeonWallpaperPainter extends CustomPainter {
  _NeonWallpaperPainter({
    required this.bgColor,
    required this.primary,
    required this.k,
    required this.grainOpacity,
    required this.showDiagonalStrokes,
    int? seed,
  }) : rnd = math.Random(seed ?? 42);

  final Color bgColor;
  final Color primary;
  final double k;
  final double grainOpacity;
  final bool showDiagonalStrokes;
  final math.Random rnd;

  @override
  void paint(Canvas canvas, Size size) {
    // --- 1) Deep background gradient ---
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          _shift(bgColor, .0),
          _shift(const Color(0xFF101114), .0),
        ],
        const [0.0, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bg);

    // --- 2) Large mesh-like radial fields (subtle) ---
    _radialField(canvas, size, Offset(size.width * .22, size.height * .25), size.width * .55, primary.withOpacity(.20 * k));
    _radialField(canvas, size, Offset(size.width * .85, size.height * .15), size.width * .45, primary.withOpacity(.15 * k));
    _radialField(canvas, size, Offset(size.width * .75, size.height * .80), size.width * .60, primary.withOpacity(.12 * k));

    // --- 3) Soft neon glows (blurred circles) ---
    _glow(canvas, Offset(size.width * .12, size.height * .70), size.width * .25, primary.withOpacity(.22 * k), sigma: 48);
    _glow(canvas, Offset(size.width * .88, size.height * .35), size.width * .22, primary.withOpacity(.18 * k), sigma: 44);

    // --- 4) Subtle diagonal strokes (texture) ---
    if (showDiagonalStrokes) {
      final stroke = Paint()
        ..color = Colors.white.withOpacity(0.018 * k)
        ..strokeWidth = 1.0
        ..isAntiAlias = true;
      final step = 24.0;
      for (double i = -size.height; i < size.width; i += step) {
        final p1 = Offset(i, 0);
        final p2 = Offset(i + size.height, size.height);
        canvas.drawLine(p1, p2, stroke);
      }
    }

    // --- 5) Fine grain (random speckles) ---
    final dots = (1200 * k).round();
    final dotPaint = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < dots; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = grainOpacity * (0.6 + rnd.nextDouble() * 0.8);
      dotPaint
        ..color = (rnd.nextBool() ? Colors.white : Colors.black).withOpacity(a)
        ..strokeWidth = rnd.nextDouble() * 0.8 + 0.2;
      canvas.drawPoints(ui.PointMode.points, [Offset(x, y)], dotPaint);
    }

    // --- 6) Vignette (focus content) ---
    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * .5, size.height * .5),
        size.shortestSide * .75,
        [
          Colors.transparent,
          Colors.black.withOpacity(0.18),
        ],
        const [0.55, 1.0],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  // Helper: big radial field with smooth fade
  void _radialField(Canvas canvas, Size size, Offset c, double r, Color color) {
    final shader = ui.Gradient.radial(
      c,
      r,
      [
        color,
        color.withOpacity(0.05),
        Colors.transparent,
      ],
      const [0.0, 0.55, 1.0],
    );
    final paint = Paint()..shader = shader;
    canvas.drawCircle(c, r, paint);
  }

  // Helper: glow circle with blur
  void _glow(Canvas canvas, Offset c, double r, Color color, {double sigma = 36}) {
    final paint = Paint()
      ..color = color
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma);
    canvas.drawCircle(c, r, paint);
  }

  Color _shift(Color base, double amount) {
    // keep dark base stable (we just return base; hook exists for future tweaks)
    return base;
  }

  @override
  bool shouldRepaint(covariant _NeonWallpaperPainter old) =>
      old.bgColor != bgColor ||
          old.primary != primary ||
          old.k != k ||
          old.grainOpacity != grainOpacity ||
          old.showDiagonalStrokes != showDiagonalStrokes;
}
