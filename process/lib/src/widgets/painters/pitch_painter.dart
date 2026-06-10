import 'dart:math' as math;
import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class PitchPainter extends CustomPainter {
  final ValueNotifier<VisualizerData> dataNotifier;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  PitchPainter({
    required this.dataNotifier,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  }) : super(repaint: dataNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    final history = dataNotifier.value.pitchHistory;
    final int len = history.length;
    if (len == 0) return;

    // 1. Calculate dynamic Y-axis bounds based on history (exclude 0.0 which means silent/no pitch)
    double minHz = 80.0;
    double maxHz = 500.0;

    final activePitches = history.where((hz) => hz > 20.0).toList();
    if (activePitches.isNotEmpty) {
      double minActive = activePitches.reduce(math.min);
      double maxActive = activePitches.reduce(math.max);
      if (maxActive - minActive < 60.0) {
        // Minimum window height of 120 Hz centered around the mean
        final double mean = (maxActive + minActive) / 2;
        minHz = math.max(0.0, mean - 60.0);
        maxHz = mean + 60.0;
      } else {
        // Add 15% padding
        final double padding = (maxActive - minActive) * 0.15;
        minHz = math.max(0.0, minActive - padding);
        maxHz = maxActive + padding;
      }
    }

    // 2. Draw background grid and reference guides
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final refPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw reference notes if they fit in the range
    final Map<String, double> references = {
      'C4 (261.6Hz)': 261.63,
      'E4 (329.6Hz)': 329.63,
      'A4 (440Hz)': 440.0,
      'C5 (523.3Hz)': 523.25,
    };

    final double heightScale = size.height / (maxHz - minHz);
    const double rightPadding = 75.0;

    references.forEach((label, hz) {
      if (hz >= minHz && hz <= maxHz) {
        final double y = size.height - (hz - minHz) * heightScale;
        // Draw solid reference line
        canvas.drawLine(Offset(0, y), Offset(size.width - rightPadding, y), refPaint);

        // Draw note label
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(size.width - rightPadding + 5, y - 6));
      }
    });

    // Draw standard horizontal grids if no reference notes were drawn
    if (references.keys.every((k) => references[k]! < minHz || references[k]! > maxHz)) {
      const int gridLines = 3;
      for (int i = 1; i <= gridLines; i++) {
        final y = size.height * i / (gridLines + 1);
        canvas.drawLine(Offset(0, y), Offset(size.width - rightPadding, y), gridPaint);

        final double hzVal = maxHz - (i / (gridLines + 1)) * (maxHz - minHz);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${hzVal.toStringAsFixed(0)} Hz',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 8.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(size.width - rightPadding + 5, y - 6));
      }
    }

    // 3. Draw pitch history line
    final path = Path();
    final double stepX = (size.width - rightPadding) / (len - 1);

    bool hasMoved = false;
    for (int i = 0; i < len; i++) {
      final hz = history[i];
      final x = i * stepX;

      if (hz <= 20.0) {
        // Break the line path during silence (no pitch)
        hasMoved = false;
        continue;
      }

      final double y = size.height - (hz - minHz) * heightScale;

      if (!hasMoved) {
        path.moveTo(x, y);
        hasMoved = true;
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // 4. Draw current value pointer dot at the end of the history line
    final double latestHz = history.last;
    if (latestHz > 20.0) {
      final double x = size.width - rightPadding;
      final double y = size.height - (latestHz - minHz) * heightScale;

      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = lineColor);
      canvas.drawCircle(
        Offset(x, y),
        7.0,
        Paint()
          ..color = lineColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PitchPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}
