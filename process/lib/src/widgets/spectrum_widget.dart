import 'package:audio_process/src/widgets/painters/spectrum_painter.dart' show SpectrumPainter;
import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class SpectrumWidget extends StatelessWidget {
  final ValueNotifier<VisualizerData> dataNotifier;

  const SpectrumWidget({super.key, required this.dataNotifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.equalizer, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'FREQ. SPECTRUM (FFT)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRect(
                child: CustomPaint(
                  painter: SpectrumPainter(
                    dataNotifier: dataNotifier,
                    startColor: theme.colorScheme.secondary,
                    endColor: theme.colorScheme.tertiary,
                    gridColor: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
