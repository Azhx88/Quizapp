import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Brief (~900 ms) full-screen burst overlay shown the instant an answer is
/// revealed. Fireworks for a correct answer, water tide for a wrong answer.
///
/// Usage: insert `ResultBurst(visible: ans.isRevealed, isCorrect: ans.isCorrect)`
/// inside a Stack on the answer screen. The widget self-fades and removes
/// itself from the layout when not visible.
class ResultBurst extends StatefulWidget {
  /// True once the answer has been revealed (drives the burst).
  final bool visible;

  /// True for a correct answer (fire), false for wrong (water), null otherwise.
  final bool? isCorrect;

  const ResultBurst({super.key, required this.visible, required this.isCorrect});

  @override
  State<ResultBurst> createState() => _ResultBurstState();
}

class _ResultBurstState extends State<ResultBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _wasVisible = false;
  bool _wasCorrect = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant ResultBurst old) {
    super.didUpdateWidget(old);
    final shouldFire = widget.visible && widget.isCorrect != null;
    if (shouldFire && !_wasVisible) {
      _wasCorrect = widget.isCorrect == true;
      _ctrl.forward(from: 0);
    } else if (!shouldFire && _wasVisible) {
      _ctrl.reset();
    }
    _wasVisible = shouldFire;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Must be placed as a direct child of a Stack — uses Positioned.fill so the
  // burst paints over the entire stack area, ignoring pointer events so taps
  // pass through to the answer widgets underneath.
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            if (_ctrl.value == 0) return const SizedBox.shrink();
            return CustomPaint(
              painter: _wasCorrect
                  ? _FireworksPainter(t: _ctrl.value)
                  : _WaterPainter(t: _ctrl.value),
            );
          },
        ),
      ),
    );
  }
}

/// Fireworks — three colored shells launch and burst across the upper half
/// of the screen. Each shell radiates particles outward, gravity drags them
/// down, and they fade as the animation ends. Replaces the static-flame
/// effect that felt stuck in place.
class _FireworksPainter extends CustomPainter {
  final double t;
  _FireworksPainter({required this.t});

  // Each shell: relative origin (x, y as fractions of size), launch time,
  // and a base color palette.
  static const _shells = <_Shell>[
    _Shell(0.28, 0.34, 0.00, [Color(0xFFFFD740), Color(0xFFFF8A65)]),
    _Shell(0.72, 0.28, 0.18, [Color(0xFF80D8FF), Color(0xFFB388FF)]),
    _Shell(0.50, 0.46, 0.36, [Color(0xFFFF80AB), Color(0xFFFFFF8D)]),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Soft warm flash on the first shell so the screen reads as celebration.
    final flashAlpha = (1.0 - (2 * t - 0.4).abs() * 1.2).clamp(0.0, 1.0);
    final flashPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF59D).withValues(alpha: 0.30 * flashAlpha),
          const Color(0xFFFFAB40).withValues(alpha: 0.12 * flashAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.4),
        radius: size.longestSide * 0.7,
      ));
    canvas.drawRect(Offset.zero & size, flashPaint);

    final particlePaint = Paint()..style = PaintingStyle.fill;
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final shell in _shells) {
      final shellT = (t - shell.launchAt) / (1.0 - shell.launchAt);
      if (shellT <= 0) continue;
      final st = shellT.clamp(0.0, 1.0);

      final originX = size.width * shell.x;
      final originY = size.height * shell.y;

      // Per-shell deterministic RNG so the burst pattern is stable across
      // frames — no jittering that would look like noise.
      final rng = math.Random(shell.launchAt.hashCode ^ 0x9E3779B9);
      const particles = 22;

      for (int i = 0; i < particles; i++) {
        // Even angle distribution + small jitter.
        final angle = (i / particles) * math.pi * 2 +
            (rng.nextDouble() - 0.5) * 0.18;
        final speed = (0.55 + rng.nextDouble() * 0.45) * size.shortestSide * 0.45;

        // Position: outward + gravity drop. Ease-out on radial speed so
        // particles fan out fast then slow down.
        final ease = 1 - math.pow(1 - st, 2.0).toDouble();
        final r = speed * ease;
        final gravity = size.height * 0.35 * st * st;

        final px = originX + math.cos(angle) * r;
        final py = originY + math.sin(angle) * r + gravity;

        // Trail behind each particle — a short streak in the direction of
        // motion. Length tapers as the particle fades.
        final trailLen = 14 * (1 - st);
        final tx = px - math.cos(angle) * trailLen;
        final ty = py - math.sin(angle) * trailLen - gravity * 0.15;

        // Color: lerp through the shell palette + gold finish.
        final color = Color.lerp(shell.colors[0], shell.colors[1], st)!;
        final alpha = (1.0 - st) * (1.0 - st);

        trailPaint
          ..color = color.withValues(alpha: alpha * 0.45)
          ..strokeWidth = 1.6;
        canvas.drawLine(Offset(tx, ty), Offset(px, py), trailPaint);

        particlePaint.color = color.withValues(alpha: alpha);
        canvas.drawCircle(Offset(px, py), 2.6 * (1 - st * 0.5), particlePaint);
      }

      // Bright burst flash at ignition — a quick radial glow that fades fast.
      if (st < 0.25) {
        final ignite = 1.0 - (st / 0.25);
        canvas.drawCircle(
          Offset(originX, originY),
          18 * ignite,
          Paint()
            ..color = shell.colors[0].withValues(alpha: 0.55 * ignite),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => old.t != t;
}

class _Shell {
  final double x;
  final double y;
  final double launchAt;
  final List<Color> colors;
  const _Shell(this.x, this.y, this.launchAt, this.colors);
}

/// Water — cool blue tide sweeping top→bottom across the whole screen.
/// Single fluid swipe, no waiting/hang.
class _WaterPainter extends CustomPainter {
  final double t;
  _WaterPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Smoothed alpha curve — no plateau in the middle so the swipe feels
    // continuous rather than "hanging" mid-frame.
    final fade = (1.0 - (2 * t - 1).abs()).clamp(0.0, 1.0);

    // Soft blue overlay tinting the whole screen.
    final overlayPaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.18 * fade);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // Tide front — full-width, sweeps from top to bottom.
    final crestY = size.height * (t * 1.15 - 0.05);
    final wobbleAmp = 18 * fade;
    final wavePath = Path()..moveTo(0, -10);
    for (double x = 0; x <= size.width; x += 14) {
      final wobble = math.sin(x / 36 + t * 7) * wobbleAmp;
      wavePath.lineTo(x, crestY + wobble);
    }
    wavePath
      ..lineTo(size.width, -10)
      ..close();

    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF01579B).withValues(alpha: 0.55 * (1 - t * 0.4)),
          const Color(0xFF0288D1).withValues(alpha: 0.45 * (1 - t * 0.4)),
          const Color(0xFF4FC3F7).withValues(alpha: 0.30 * (1 - t * 0.5)),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(wavePath, wavePaint);

    // Foam crest — thin white wobble line along the front edge.
    final foamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 * fade)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final foam = Path();
    for (double x = 0; x <= size.width; x += 14) {
      final wobble = math.sin(x / 36 + t * 7) * wobbleAmp;
      if (x == 0) {
        foam.moveTo(x, crestY + wobble);
      } else {
        foam.lineTo(x, crestY + wobble);
      }
    }
    canvas.drawPath(foam, foamPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) => old.t != t;
}
