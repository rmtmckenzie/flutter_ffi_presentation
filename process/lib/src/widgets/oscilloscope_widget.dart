import 'package:audio_process/src/widgets/painters/oscilloscope_painter.dart';
import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class OscilloscopeWidget extends StatelessWidget {
  final ValueNotifier<VisualizerData> dataNotifier;

  const OscilloscopeWidget({
    super.key,
    required this.dataNotifier,
  });

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
                Icon(Icons.waves, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'TIME DOMAIN OSCILLOSCOPE',
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
                  painter: OscilloscopePainter(
                    dataNotifier: dataNotifier,
                    waveColor: theme.colorScheme.primary,
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
