import 'dart:math' as math;
import 'package:audio_process/src/widgets/painters/volume_painter.dart';
import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class VolumeWidget extends StatelessWidget {
  final ValueNotifier<VisualizerData> dataNotifier;

  const VolumeWidget({
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
                Icon(Icons.volume_up, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'LOUDNESS LEVEL (RMS)',
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
              child: Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: VolumePainter(
                          dataNotifier: dataNotifier,
                          trackColor: Colors.white.withValues(alpha: 0.04),
                          volumeColor: theme.colorScheme.tertiary,
                        ),
                      ),
                      Center(
                        child: ValueListenableBuilder<VisualizerData>(
                          valueListenable: dataNotifier,
                          builder: (context, data, _) {
                            final double vol = data.telemetry?.volume ?? 0.0;
                            final double db = vol > 0.0000001
                                ? (90.0 + 20.0 * (math.log(vol) / math.ln10)).clamp(0.0, 120.0)
                                : 0.0;
                            final String dbText = '${db.toStringAsFixed(1)} dB';

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dbText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'RMS: ${vol.toStringAsFixed(3)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
