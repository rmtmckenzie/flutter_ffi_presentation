import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class SpectrumPainter extends CustomPainter {
  final ValueNotifier<VisualizerData> dataNotifier;
  final Color startColor;
  final Color endColor;
  final Color gridColor;

  SpectrumPainter({
    required this.dataNotifier,
    required this.startColor,
    required this.endColor,
    required this.gridColor,
  }) : super(repaint: dataNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid lines (horizontal only for a scientific spectrogram look)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const int horizontalLines = 3;
    for (int i = 1; i <= horizontalLines; i++) {
      final y = size.height * i / (horizontalLines + 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final heights = dataNotifier.value.spectrumHeights;
    final int barCount = heights.length;
    if (barCount == 0) return;

    // Layout configuration
    const double gap = 2.0;
    final double totalSpacing = (barCount - 1) * gap;
    final double barWidth = (size.width - totalSpacing) / barCount;

    final rectPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final double hFactor = heights[i];
      final double barHeight = hFactor * size.height * 0.92; // leave margin at top

      // Draw a tiny placeholder dot even if there is no audio, for visual consistency
      final double drawHeight = barHeight < 2.0 ? 2.0 : barHeight;

      final double x = i * (barWidth + gap);
      final double y = size.height - drawHeight;

      // Apply vertical gradient relative to this specific bar bounds
      rectPaint.shader = LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(x, y, barWidth, drawHeight));

      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barWidth, drawHeight), const Radius.circular(2.0));
      canvas.drawRRect(rrect, rectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumPainter oldDelegate) {
    return oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor ||
        oldDelegate.gridColor != gridColor;
  }
}
