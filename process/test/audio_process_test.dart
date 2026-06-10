// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_process/audio_process.dart';
import 'package:test/test.dart';

Float32List _generateSineWave(double frequency, double sampleRate, int length, {double amplitude = 0.5}) {
  final buffer = Float32List(length);
  for (int i = 0; i < length; i++) {
    buffer[i] = amplitude * math.sin(2 * math.pi * frequency * i / sampleRate);
  }
  return buffer;
}

Float32List _bytesToFloat32List(Uint8List bytes) {
  final int16List = Int16List.view(bytes.buffer);
  final floatList = Float32List(int16List.length);
  for (int i = 0; i < int16List.length; i++) {
    floatList[i] = int16List[i] / 32768.0;
  }
  return floatList;
}

Uint8List _generateSineWaveBytes(double frequency, double sampleRate, int length, {double amplitude = 0.5}) {
  final bytes = Uint8List(length * 2);
  final byteData = ByteData.view(bytes.buffer);
  for (int i = 0; i < length; i++) {
    final double sampleValue = amplitude * math.sin(2 * math.pi * frequency * i / sampleRate);
    final int intVal = (sampleValue * 32767.0).clamp(-32768.0, 32767.0).round();
    byteData.setInt16(i * 2, intVal, Endian.host);
  }
  return bytes;
}

Uint8List _generateSineWaveWithNoiseBytes(
  double targetFrequency,
  double sampleRate,
  int length, {
  double targetAmplitude = 0.5,
  double noiseAmplitude = 0.05,
}) {
  final bytes = Uint8List(length * 2);
  final byteData = ByteData.view(bytes.buffer);
  final random = math.Random(42); // Seeded random for deterministic behavior
  
  double noiseFrequency = 300.0;
  for (int i = 0; i < length; i++) {
    // Change noise frequency randomly every 50ms (approx 2205 samples at 44.1kHz)
    if (i % 2205 == 0) {
      noiseFrequency = 100.0 + random.nextDouble() * 1000.0;
    }
    final double targetSample = targetAmplitude * math.sin(2 * math.pi * targetFrequency * i / sampleRate);
    final double noiseSample = noiseAmplitude * math.sin(2 * math.pi * noiseFrequency * i / sampleRate);
    final double combinedSample = targetSample + noiseSample;
    final int intVal = (combinedSample * 32767.0).clamp(-32768.0, 32767.0).round();
    byteData.setInt16(i * 2, intVal, Endian.host);
  }
  return bytes;
}

void main() {
  group('AudioProcessorWorker', () {
    late ReceivePort uiReceivePort;

    setUp(() {
      uiReceivePort = ReceivePort();
    });

    tearDown(() {
      uiReceivePort.close();
    });

    test('initializes and sends command port back to UI', () async {
      final completer = Completer<SendPort>();
      final sub = uiReceivePort.listen((message) {
        if (message is SendPort) {
          completer.complete(message);
        }
      });

      // Spawn/create the worker in the same isolate for basic testing
      AudioProcessorWorker(uiReceivePort.sendPort, const Duration(milliseconds: 10));

      final workerCommandPort = await completer.future;
      expect(workerCommandPort, isNotNull);

      // Clean up the worker
      workerCommandPort.send("STOP");
      await sub.cancel();
    });

    test('calculates volume, frequency and FFT from fed buffers', () async {
      final portCompleter = Completer<SendPort>();
      final telemetryCompleter = Completer<AudioTelemetry>();

      final sub = uiReceivePort.listen((message) {
        if (message is SendPort) {
          portCompleter.complete(message);
        } else if (message is AudioTelemetry) {
          if (!telemetryCompleter.isCompleted) {
            telemetryCompleter.complete(message);
          }
        }
      });

      // Create worker
      AudioProcessorWorker(uiReceivePort.sendPort, const Duration(milliseconds: 10));
      final workerCommandPort = await portCompleter.future;

      // Feed a 440 Hz sine wave
      // Needs to be at least fftSize (1024) to trigger analysis
      final sineWave = _generateSineWave(440, 44100, 1024, amplitude: 0.5);
      workerCommandPort.send(sineWave);

      // Wait for telemetry response
      final telemetry = await telemetryCompleter.future.timeout(const Duration(seconds: 2));

      expect(telemetry, isNotNull);
      
      // 1. Volume: RMS of sine wave with peak amplitude A=0.5 should be ~0.3535
      expect(telemetry.volume, closeTo(0.3535, 0.05));

      // 2. Frequency: Should be close to 440 Hz
      expect(telemetry.estimatedFrequency, closeTo(440.0, 50.0));

      // 3. Time domain samples: should match the analysis block size (1024)
      expect(telemetry.timeDomainSamples.length, equals(1024));

      // 4. Frequency samples (FFT): should have length 512 (fftSize / 2)
      expect(telemetry.frequencySamples.length, equals(512));

      // 5. Check that the peak frequency bin corresponds to ~440 Hz
      // Frequency resolution = 44100 / 1024 = 43.066 Hz per bin.
      // Expected peak bin = 440 / 43.066 = ~10.2. So peak should be at bin 10 or nearby.
      double maxVal = -1.0;
      int peakBinIndex = -1;
      for (int i = 0; i < telemetry.frequencySamples.length; i++) {
        if (telemetry.frequencySamples[i] > maxVal) {
          maxVal = telemetry.frequencySamples[i];
          peakBinIndex = i;
        }
      }
      expect(peakBinIndex, anyOf(9, 10, 11));

      // Clean up
      workerCommandPort.send("STOP");
      await sub.cancel();
    });

    test('ignores calculation ticks until minimum samples are written', () async {
      final portCompleter = Completer<SendPort>();
      final telemetryList = <AudioTelemetry>[];
      final completer = Completer<void>();

      final sub = uiReceivePort.listen((message) {
        if (message is SendPort) {
          portCompleter.complete(message);
        } else if (message is AudioTelemetry) {
          telemetryList.add(message);
          completer.complete();
        }
      });

      // Create worker
      AudioProcessorWorker(uiReceivePort.sendPort, const Duration(milliseconds: 10));
      final workerCommandPort = await portCompleter.future;

      // Feed too few samples (500 samples, less than fftSize = 1024)
      final smallBuffer = Float32List(500);
      workerCommandPort.send(smallBuffer);

      // Wait a short duration to ensure multiple ticks run
      await Future.delayed(const Duration(milliseconds: 50));

      // No telemetry should have been emitted because total samples written (500) < fftSize (1024)
      expect(telemetryList, isEmpty);

      // Now feed the rest of the samples to reach 1024
      final extraBuffer = Float32List(524);
      workerCommandPort.send(extraBuffer);

      // Now telemetry should be received
      await completer.future.timeout(const Duration(seconds: 2));
      expect(telemetryList, isNotEmpty);

      // Clean up
      workerCommandPort.send("STOP");
      await sub.cancel();
    });

    test('detects estimated pitch for multiple notes accurately', () async {
      final portCompleter = Completer<SendPort>();
      final telemetryList = <AudioTelemetry>[];

      final sub = uiReceivePort.listen((message) {
        if (message is SendPort) {
          portCompleter.complete(message);
        } else if (message is AudioTelemetry) {
          telemetryList.add(message);
        }
      });

      // Spawn worker
      AudioProcessorWorker(uiReceivePort.sendPort, const Duration(milliseconds: 10));
      final workerCommandPort = await portCompleter.future;

      // Test notes: C4 (261.63 Hz), A4 (440.0 Hz), C5 (523.25 Hz)
      final testNotes = {
        261.63: 'C4',
        440.0: 'A4',
        523.25: 'C5',
      };

      for (final hz in testNotes.keys) {
        telemetryList.clear();

        final sineWave = _generateSineWave(hz, 44100, 1024, amplitude: 0.5);

        // Feed multiple buffers to allow the median filter and low-pass filter to converge
        for (int i = 0; i < 8; i++) {
          workerCommandPort.send(sineWave);
          await Future.delayed(const Duration(milliseconds: 15));
        }

        expect(telemetryList, isNotEmpty);
        final latestTelemetry = telemetryList.last;

        expect(latestTelemetry.volume, greaterThan(0.2));
        expect(latestTelemetry.estimatedFrequency, closeTo(hz, 40.0));
      }

      // Clean up
      workerCommandPort.send("STOP");
      await sub.cancel();
    });

    test('respects configurable noise gate cutoff level', () async {
      final portCompleter = Completer<SendPort>();
      final telemetryCompleter = Completer<AudioTelemetry>();

      final sub = uiReceivePort.listen((message) {
        if (message is SendPort) {
          portCompleter.complete(message);
        } else if (message is AudioTelemetry) {
          if (!telemetryCompleter.isCompleted) {
            telemetryCompleter.complete(message);
          }
        }
      });

      // Spawn worker with a custom high noise gate (e.g. 75.0 dB SPL, which maps to ~0.178 RMS)
      AudioProcessorWorker(
        uiReceivePort.sendPort,
        const Duration(milliseconds: 10),
        noiseGateDb: 75.0,
      );
      final workerCommandPort = await portCompleter.future;

      // Feed a quiet sine wave with amplitude 0.2 (RMS ~0.14)
      // Since RMS 0.14 is below threshold 0.4, pitch should be ignored (0.0)
      final sineWave = _generateSineWave(440, 44100, 1024, amplitude: 0.2);
      workerCommandPort.send(sineWave);

      final telemetry = await telemetryCompleter.future.timeout(const Duration(seconds: 2));
      expect(telemetry.volume, closeTo(0.14, 0.05));
      expect(telemetry.estimatedFrequency, equals(0.0)); // Gated!

      // Clean up
      workerCommandPort.send("STOP");
      await sub.cancel();
    });

    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

    // Test every note from F2 (MIDI 41) up to A#5/Bb5 (MIDI 82)
    for (int midi = 41; midi <= 82; midi++) {
      final String noteName = '${noteNames[midi % 12]}${(midi ~/ 12) - 1}';
      final double hz = 440.0 * math.pow(2.0, (midi - 69) / 12.0);

      test('estimates pitch from raw PCM byte input for $noteName (${hz.toStringAsFixed(2)} Hz) within 100ms', () async {
        final portCompleter = Completer<SendPort>();
        final telemetryList = <AudioTelemetry>[];

        final sub = uiReceivePort.listen((message) {
          if (message is SendPort) {
            portCompleter.complete(message);
          } else if (message is AudioTelemetry) {
            telemetryList.add(message);
          }
        });

        // Spawn worker with default settings (35.0 dB SPL gate)
        AudioProcessorWorker(uiReceivePort.sendPort, const Duration(milliseconds: 10));
        final workerCommandPort = await portCompleter.future;

        // Generate 2048 samples of sine wave as 16-bit PCM byte array
        final Uint8List byteBuffer = _generateSineWaveBytes(hz, 44100, 2048, amplitude: 0.5);

        // Convert PCM bytes to Float32List as the mic engine does
        final Float32List floatBuffer = _bytesToFloat32List(byteBuffer);

        // Feed the buffer to the processor
        workerCommandPort.send(floatBuffer);

        // Wait up to 100ms for the pitch estimate to settle and check it
        final stopwatch = Stopwatch()..start();
        double detectedPitch = 0.0;
        
        while (stopwatch.elapsedMilliseconds < 50) {
          await Future.delayed(const Duration(milliseconds: 5));
          if (telemetryList.isNotEmpty) {
            final latest = telemetryList.last;
            if (latest.estimatedFrequency > 0.0) {
              detectedPitch = latest.estimatedFrequency;
              break;
            }
          }
        }

        expect(detectedPitch, greaterThan(0.0), reason: 'Pitch tracking timed out within 100ms for $noteName ($hz Hz)');
        // Zero-crossing pitch estimation has some variance, check it is within a reasonable tolerance
        // Use a minimum absolute tolerance of 25.0 Hz to account for low frequency quantization steps,
        // and 15% tolerance for higher frequencies.
        final double tolerance = math.max(25.0, hz * 0.15);
        expect(detectedPitch, closeTo(hz, tolerance), reason: 'Detected $detectedPitch Hz instead of $hz Hz for $noteName');

        // Clean up
        workerCommandPort.send("STOP");
        await sub.cancel();
      });
    }

    // Test every note from F2 (MIDI 41) up to A#5/Bb5 (MIDI 82) with background noise
    for (int midi = 41; midi <= 82; midi++) {
      final String noteName = '${noteNames[midi % 12]}${(midi ~/ 12) - 1}';
      final double hz = 440.0 * math.pow(2.0, (midi - 69) / 12.0);

      test('estimates pitch with background noise for $noteName (${hz.toStringAsFixed(2)} Hz) steadily for 1 second', () async {
        final portCompleter = Completer<SendPort>();
        final telemetryList = <AudioTelemetry>[];

        final sub = uiReceivePort.listen((message) {
          if (message is SendPort) {
            portCompleter.complete(message);
          } else if (message is AudioTelemetry) {
            telemetryList.add(message);
          }
        });

        // Spawn worker with default settings (35.0 dB SPL gate) and fast tick interval (5ms)
        AudioProcessorWorker(uiReceivePort.sendPort, const Duration(milliseconds: 5));
        final workerCommandPort = await portCompleter.future;

        // Generate exactly 43 chunks of 1024 samples (44032 samples ~ 1 second)
        // mixed with random background noise of lower volume (amplitude 0.05 vs target 0.5)
        final Uint8List byteBuffer = _generateSineWaveWithNoiseBytes(
          hz,
          44100,
          44032,
          targetAmplitude: 0.5,
          noiseAmplitude: 0.05,
        );

        // Convert PCM bytes to Float32List
        final Float32List floatBuffer = _bytesToFloat32List(byteBuffer);

        // Feed the buffer to the processor in chunks of 1024 samples every 5ms
        const int chunkSize = 1024;
        const int numChunks = 43;

        for (int c = 0; c < numChunks; c++) {
          final chunk = Float32List.sublistView(
            floatBuffer,
            c * chunkSize,
            (c + 1) * chunkSize,
          );
          workerCommandPort.send(chunk);
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Wait a brief moment to ensure the final calculation is processed
        await Future.delayed(const Duration(milliseconds: 10));

        expect(telemetryList, isNotEmpty);

        // Check that after an initial settling period (first 5 frames),
        // the estimated pitch remains stable and close to target frequency throughout the remaining duration
        final double tolerance = math.max(25.0, hz * 0.15);
        int checkedFramesCount = 0;

        for (int i = 5; i < telemetryList.length; i++) {
          final double estimated = telemetryList[i].estimatedFrequency;
          expect(estimated, closeTo(hz, tolerance),
              reason: 'Pitch fluctuated to $estimated Hz instead of $hz Hz at frame $i for $noteName with noise');
          checkedFramesCount++;
        }

        expect(checkedFramesCount, greaterThan(0), reason: 'Not enough telemetry frames were generated to verify stability');

        // Clean up
        workerCommandPort.send("STOP");
        await sub.cancel();
      });
    }
  });

  group('AudioPipeline', () {
    test('lifecycle: initialization, processing, and disposal', () async {
      final pipeline = AudioPipeline();
      final telemetryList = <AudioTelemetry>[];

      // Initialize with a fast tick interval to speed up the test
      await pipeline.initialize(updateInterval: const Duration(milliseconds: 10));

      final subscription = pipeline.telemetryStream.listen(telemetryList.add);

      // Wait for the isolate to start and initialize the SendPort.
      // This is a brief async delay.
      await Future.delayed(const Duration(milliseconds: 50));

      // Feed a 1024 sample 880 Hz sine wave
      final sineWave = _generateSineWave(880, 44100, 1024, amplitude: 0.8);
      pipeline.feedRawBuffer(sineWave);

      // Wait for telemetry to be received on the stream
      final stopwatch = Stopwatch()..start();
      while (telemetryList.isEmpty && stopwatch.elapsedMilliseconds < 2000) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(telemetryList, isNotEmpty);
      final telemetry = telemetryList.first;

      // RMS of peak amplitude 0.8 is ~0.565
      expect(telemetry.volume, closeTo(0.565, 0.05));
      // Frequency should be close to 880 Hz
      expect(telemetry.estimatedFrequency, closeTo(880.0, 50.0));
      expect(telemetry.timeDomainSamples.length, 1024);
      expect(telemetry.frequencySamples.length, 512);

      // Verify the peak frequency bin for 880 Hz
      // 880 / (44100 / 1024) = 880 / 43.066 = ~20.4
      double maxVal = -1.0;
      int peakBinIndex = -1;
      for (int i = 0; i < telemetry.frequencySamples.length; i++) {
        if (telemetry.frequencySamples[i] > maxVal) {
          maxVal = telemetry.frequencySamples[i];
          peakBinIndex = i;
        }
      }
      expect(peakBinIndex, anyOf(19, 20, 21));

      // Clean up
      await subscription.cancel();
      pipeline.dispose();
    });
  });
}
