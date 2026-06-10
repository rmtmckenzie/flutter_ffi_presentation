import 'dart:math' as math;

import 'package:audio_process/src/audio_telemetry.dart';

class VisualizerData {
  final AudioTelemetry? telemetry;
  final List<double> volumeHistory;
  final List<double> pitchHistory;
  final List<double> spectrumHeights; // Log-grouped decayed heights for 64 bars

  VisualizerData({
    required this.telemetry,
    required this.volumeHistory,
    required this.pitchHistory,
    required this.spectrumHeights,
  });

  factory VisualizerData.empty() {
    return VisualizerData(
      telemetry: null,
      volumeHistory: List.filled(100, 0.0),
      pitchHistory: List.filled(100, 0.0),
      spectrumHeights: List.filled(64, 0.0),
    );
  }

  VisualizerData copyWithUpdatedTelemetry(AudioTelemetry newTelemetry, int maxHistoryLength) {
    final newVolumeHistory = List<double>.from(volumeHistory)..add(newTelemetry.volume);
    if (newVolumeHistory.length > maxHistoryLength) {
      newVolumeHistory.removeAt(0);
    }

    // Zero-Crossing pitch tracker may produce NaN or Infinity if there is absolute silence or error
    double pitchValue = newTelemetry.estimatedFrequency;
    if (pitchValue.isNaN || pitchValue.isInfinite) {
      pitchValue = 0.0;
    }

    final newPitchHistory = List<double>.from(pitchHistory)..add(pitchValue);
    if (newPitchHistory.length > maxHistoryLength) {
      newPitchHistory.removeAt(0);
    }

    // Log-grouped, decayed frequency spectrum calculation
    final newSpectrum = List<double>.filled(64, 0.0);
    final rawFFT = newTelemetry.frequencySamples;

    if (rawFFT.isNotEmpty) {
      for (int i = 0; i < 64; i++) {
        // Group bins logarithmically: pow(2, 9) = 512 bins
        int startBin = (math.pow(2, (i / 64) * 9) - 1).round().clamp(0, rawFFT.length - 1);
        int endBin = (math.pow(2, ((i + 1) / 64) * 9) - 1).round().clamp(0, rawFFT.length - 1);
        if (endBin <= startBin) endBin = startBin + 1;

        double sum = 0.0;
        for (int bin = startBin; bin < endBin; bin++) {
          sum += rawFFT[bin];
        }
        double avg = sum / (endBin - startBin);
        // Apply log scaling to normalize standard audio dynamic ranges
        double val = (math.log(avg + 1.0) / 4.0).clamp(0.0, 1.0);

        // Apply decay
        double prevVal = spectrumHeights.length > i ? spectrumHeights[i] : 0.0;
        const double decayRate = 0.08; // smooth gravity decay rate
        newSpectrum[i] = math.max(val, prevVal - decayRate).clamp(0.0, 1.0);
      }
    }

    return VisualizerData(
      telemetry: newTelemetry,
      volumeHistory: newVolumeHistory,
      pitchHistory: newPitchHistory,
      spectrumHeights: newSpectrum,
    );
  }
}
