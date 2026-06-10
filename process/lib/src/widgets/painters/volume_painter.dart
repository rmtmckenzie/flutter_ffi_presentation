import 'dart:math' as math;
import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class VolumePainter extends CustomPainter {
  final ValueNotifier<VisualizerData> dataNotifier;
  final Color trackColor;
  final Color volumeColor;

  VolumePainter({
    required this.dataNotifier,
    required this.trackColor,
    required this.volumeColor,
  }) : super(repaint: dataNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    final double volume = dataNotifier.value.telemetry?.volume ?? 0.0;
    final double db = volume > 0.0000001
        ? (90.0 + 20.0 * (math.log(volume) / math.ln10)).clamp(0.0, 120.0)
        : 0.0;
    final double normalizedVolume = db / 120.0;

    final double center = size.width / 2;
    final double radius = (size.width - 16) / 2; // leave padding for stroke widths

    final centerOffset = Offset(center, size.height / 2);

    // 1. Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(centerOffset, radius, trackPaint);

    // 2. Draw sweep arc (active volume indicator)
    if (normalizedVolume > 0.0) {
      final activePaint = Paint()
        ..color = volumeColor
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Add a outer glow to the active arc
      final activeGlowPaint = Paint()
        ..color = volumeColor.withValues(alpha: 0.3)
        ..strokeWidth = 14.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      // Arc starts from top (-pi / 2) and sweeps clockwise
      const double startAngle = -math.pi / 2;
      final double sweepAngle = 2 * math.pi * normalizedVolume;

      canvas.drawArc(
        Rect.fromCircle(center: centerOffset, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activeGlowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: centerOffset, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }

    // 3. Draw inner pulsing glowing circle
    final double innerMaxRadius = radius - 10;
    final double innerRadius = 8 + (innerMaxRadius - 8) * normalizedVolume;

    if (innerRadius > 0) {
      final innerPaint = Paint()
        ..color = volumeColor.withValues(alpha: 0.12 + 0.25 * normalizedVolume)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerOffset, innerRadius, innerPaint);

      // Add a glowing core in the center of the pulse
      final corePaint = Paint()
        ..color = volumeColor.withValues(alpha: 0.4 + 0.4 * normalizedVolume)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(centerOffset, innerRadius * 0.4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VolumePainter oldDelegate) {
    return oldDelegate.trackColor != trackColor || oldDelegate.volumeColor != volumeColor;
  }
}
