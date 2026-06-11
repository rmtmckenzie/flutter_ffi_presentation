import 'dart:math' as math;
import 'package:audio_process/src/widgets/painters/pitch_painter.dart';
import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:flutter/material.dart';

class PitchTrackerWidget extends StatelessWidget {
  final ValueNotifier<VisualizerData> dataNotifier;

  const PitchTrackerWidget({
    super.key,
    required this.dataNotifier,
  });

  String _hzToNote(double hz) {
    if (hz <= 20.0 || hz.isNaN || hz.isInfinite) return 'Silence';
    // Standard MIDI scale pitch conversion: MIDI = 12 * log2(hz / 440) + 69
    final double midi = 12 * (math.log(hz / 440.0) / math.log(2)) + 69;
    final int midiRound = midi.round();
    if (midiRound < 0 || midiRound > 127) return 'Out of Range';

    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final String note = notes[midiRound % 12];
    final int octave = (midiRound / 12).floor() - 1;

    final double cents = (midi - midiRound) * 100;
    final String centsSign = cents >= 0 ? '+' : '';
    return '$note$octave ($centsSign${cents.toStringAsFixed(0)}¢)';
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'PITCH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<VisualizerData>(
                  valueListenable: dataNotifier,
                  builder: (context, data, _) {
                    final double currentHz = data.pitchHistory.last;
                    return Text(
                      currentHz > 20.0
                          ? '${currentHz.toStringAsFixed(1)} Hz — ${_hzToNote(currentHz)}'
                          : 'Silence',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: currentHz > 20.0
                            ? theme.colorScheme.primary
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRect(
                child: CustomPaint(
                  painter: PitchPainter(
                    dataNotifier: dataNotifier,
                    lineColor: theme.colorScheme.primary,
                    gridColor: Colors.white.withValues(alpha: 0.04),
                    textColor: Colors.white,
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
