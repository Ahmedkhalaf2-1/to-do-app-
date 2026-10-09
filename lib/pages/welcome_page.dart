import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

/// Shared neon + dark palette (matches Home/Category/Calendar)
class _Palette {
  static const bg = Color(0xFF0B0B0D);       // page background
  static const card = Color(0xFF101114);     // cards (outer)
  static const cardSoft = Color(0xFF141416); // inner surfaces / fields
  static const border = Color(0xFF1E1E25);   // borders
  static const hint = Color(0xFF2A2A33);     // subtle borders

  static const primary = Color(0xFFE6FF42);  // neon yellow accent
  static const onPrimary = Color(0xFF0B0B0D);// text on primary

  static const txt = Colors.white;
  static const txtMuted = Colors.white70;
  static const txtDim = Colors.white54;
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  File? _image;

  // prevent double submit without changing UI
  bool _busy = false;

  // live background anim
  late final AnimationController _bgAnim =
  AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

  @override
  void dispose() {
    _bgAnim.dispose();
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final res = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (res == null) return;

      final dir = await getApplicationDocumentsDirectory();
      // safe filename: timestamp + original name
      final safeName = '${DateTime.now().millisecondsSinceEpoch}_${res.name}';
      final f = File('${dir.path}/$safeName');

      final bytes = await res.readAsBytes();
      await f.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() => _image = f);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick/save image: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (_busy) return; // guard re-entrancy
    _busy = true;

    try {
      final name = _name.text.trim();
      if (name.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your name')),
          );
          _nameFocus.requestFocus();
        }
        return;
      }

      final box = Hive.box<AppUser>('user');
      await box.clear();
      await box.add(AppUser(name: name, imagePath: _image?.path));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/shell');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your profile: $e')),
        );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // لو عندك MaterialApp متعشّشة وطلع لك تحذير الـ Hero،
    // تقدر مؤقتًا تطفي الـ Hero في الصفحة دي كـ workaround:
    // return HeroMode(enabled: false, child: _buildScaffold(bottomInset));

    return _buildScaffold(bottomInset);
  }

  Widget _buildScaffold(double bottomInset) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // 1) live cinematic background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgAnim,
                builder: (_, __) => CustomPaint(
                  painter: _NeonCinematicPainter(progress: _bgAnim.value),
                ),
              ),
            ),
            // 2) subtle neon halo (matching app glow)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      center: const Alignment(0.2, -0.4),
                      colors: [
                        _Palette.primary.withOpacity(.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 3) content (scrolls when needed + respects keyboard)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const SizedBox(height: 36), // بدل Spacer علشان ما يتعارضش مع الـ Scroll

                    const Text('😁', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        color: _Palette.txt,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set your name and add a photo to get started.',
                      style: TextStyle(color: _Palette.txtMuted),
                    ),

                    const SizedBox(height: 24),
                    Center(
                      child: Semantics(
                        label: 'Profile photo picker',
                        button: true,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  _Palette.primary,
                                  _Palette.primary.withOpacity(.3),
                                  _Palette.primary,
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: _Palette.card,
                              backgroundImage: _image != null ? FileImage(_image!) : null,
                              child: _image == null
                                  ? const Icon(Icons.camera_alt, color: _Palette.txtMuted, size: 28)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_outlined, size: 18, color: _Palette.txtMuted),
                        label: const Text('Choose photo', style: TextStyle(color: _Palette.txtMuted)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _name,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                      maxLength: 24,
                      style: const TextStyle(color: _Palette.txt),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Your name',
                        hintStyle: const TextStyle(color: _Palette.txtDim),
                        filled: true,
                        fillColor: _Palette.cardSoft,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _Palette.hint),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _save, // allow skipping photo
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _Palette.hint),
                              foregroundColor: _Palette.txtMuted,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            child: const Text('Skip for now', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _Palette.primary,
                              foregroundColor: _Palette.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                              elevation: 0,
                            ),
                            child: const Text('Continue', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Cinematic Painter (neon lime على دارك) =====
class _NeonCinematicPainter extends CustomPainter {
  final double progress; // 0..1 loop
  _NeonCinematicPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base gradient
    final bgGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0B0B0D), Color(0xFF121214)],
    );
    final bgPaint = Paint()..shader = bgGrad.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // soft flares
    void flare(Offset c, double r, List<Color> colors) {
      final g = RadialGradient(colors: colors, stops: const [0.0, 1.0]);
      final p = Paint()
        ..shader = g.createShader(Rect.fromCircle(center: c, radius: r))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(c, r, p);
    }

    final dx = (math.sin(progress * 2 * math.pi) * 10);
    final dy = (math.cos(progress * 2 * math.pi) * 8);

    flare(Offset(w * .82 + dx * .2, h * .18 + dy * .2), w * .55, [const Color(0x22E6FF42), Colors.transparent]);
    flare(Offset(w * .20 - dx * .2, h * .78 - dy * .2), w * .65, [const Color(0x18E6FF42), Colors.transparent]);

    _drawLightParticles(canvas, size, seed: 27, count: 18, speed: .6);
  }

  void _drawLightParticles(Canvas canvas, Size size, {required int seed, required int count, required double speed}) {
    final w = size.width;
    final h = size.height;
    final rnd = math.Random(seed);

    for (int i = 0; i < count; i++) {
      final baseX = (i * 97.0) % w;
      final baseY = (i * 53.0) % h;
      final t = (progress + i * .021) % 1.0;

      final x = (baseX + math.cos(t * 2 * math.pi) * 8 * speed) % w;
      final y = (baseY + math.sin(t * 2 * math.pi) * 10 * speed) % h;

      final r = 0.6 + (i % 3) * 0.4;
      final a = 36 + rnd.nextInt(44);

      final p = Paint()
        ..color = const Color(0xFFE6FF42).withAlpha(a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..blendMode = BlendMode.plus;

      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonCinematicPainter old) => old.progress != progress;
}
