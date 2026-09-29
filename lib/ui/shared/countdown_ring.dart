import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

class CountdownRing extends StatelessWidget {
  final int timeLeft;
  final int totalTime;
  final double size;

  const CountdownRing({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    this.size = 130,
  });

  String get _timeText {
    final minutes = timeLeft ~/ 60;
    final seconds = timeLeft % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = totalTime == 0 ? 0.0 : timeLeft / totalTime;
    final isUrgent = ratio <= 0.25;
    final ringColor =
        isUrgent ? AppColors.answerRed : AppColors.answerBlue;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          ratio: ratio.clamp(0.0, 1.0),
          color: ringColor,
          strokeWidth: size * 0.06,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _timeText,
                style: AppText.heading(
                  fontSize: size * 0.28,
                  color: AppColors.textDark,
                ).copyWith(letterSpacing: -0.5),
              ),
              Text(
                'Seconds',
                style: AppText.body(
                  fontSize: size * 0.10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.ratio,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy) - strokeWidth / 2;

    // Faint ring track
    final bgPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..color = AppColors.textDark.withValues(alpha: 0.20);
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    // Active arc
    final fgPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2,
      2 * pi * ratio,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio || old.color != color;
}
