import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class OscilloscopePainter extends CustomPainter {
  final ValueNotifier<VisualizerData> dataNotifier;
  final Color waveColor;
  final Color gridColor;

  OscilloscopePainter({
    required this.dataNotifier,
    required this.waveColor,
    required this.gridColor,
  }) : super(repaint: dataNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    final telemetry = dataNotifier.value.telemetry;

    // Draw background grid
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines
    const int horizontalLines = 4;
    for (int i = 1; i <= horizontalLines; i++) {
      final y = size.height * i / (horizontalLines + 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    const int verticalLines = 6;
    for (int i = 1; i <= verticalLines; i++) {
      final x = size.width * i / (verticalLines + 1);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (telemetry == null || telemetry.timeDomainSamples.isEmpty) {
      // Draw flat line if no telemetry
      final flatPaint = Paint()
        ..color = waveColor.withValues(alpha: 0.5)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        flatPaint,
      );
      return;
    }

    final samples = telemetry.timeDomainSamples;
    final int len = samples.length;

    // Build path
    final path = Path();
    final double stepX = size.width / (len - 1);
    final double centerY = size.height / 2;
    // Scale standard -1.0 to 1.0 sample range to canvas bounds
    final double amplitudeScale = size.height / 2 * 0.95;

    path.moveTo(0, centerY + samples[0] * amplitudeScale);
    for (int i = 1; i < len; i++) {
      final x = i * stepX;
      final y = centerY + samples[i] * amplitudeScale;
      path.lineTo(x, y);
    }

    // Paint options for glow effect
    // 1. Draw blurred background path for glow
    final glowPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.4)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(path, glowPaint);

    // 2. Draw clean sharp foreground path
    final linePaint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant OscilloscopePainter oldDelegate) {
    return oldDelegate.waveColor != waveColor || oldDelegate.gridColor != gridColor;
  }
}
