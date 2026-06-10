import 'dart:typed_data';

class AudioTelemetry {
  final double volume;               // Root Mean Square (RMS) loudness
  final double estimatedFrequency;    // Pitch tracking value via Zero-Crossing Rate
  final Float32List timeDomainSamples; // Clean wave slice for the oscilloscope
  final Float32List frequencySamples;  // FFT magnitude bins for the spectrogram/bars

  AudioTelemetry({
    required this.volume,
    required this.estimatedFrequency,
    required this.timeDomainSamples,
    required this.frequencySamples,
  });
}