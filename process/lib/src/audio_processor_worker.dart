import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart'; // High-performance FFT framework
import 'audio_telemetry.dart';
import 'pitch_ring_buffer.dart';

class AudioProcessorWorkerInput {
  final SendPort uiSendPort;
  final Duration interval;
  final double noiseGateDb;

  AudioProcessorWorkerInput(
    this.uiSendPort,
    this.interval, {
    this.noiseGateDb = 35.0,
  });
}

class AudioProcessorWorker {
  final SendPort _uiSendPort;
  final ReceivePort _commandPort = ReceivePort();
  final double noiseGateDb;
  late final double _noiseGateThreshold;

  // Configurable size for FFT analysis (Must be a power of 2 for maximum FFTEA speed)
  static const int fftSize = 1024;
  
  // Historical Ring Buffer: Large enough to handle overlap and smooth visualizations
  static const int ringBufferSize = 4096;
  final Float32List _ringBuffer = Float32List(ringBufferSize);
  int _writeIndex = 0;
  int _totalSamplesWritten = 0;

  // FFTEA Engine setup
  late final FFT _fft;
  late final Timer _ticker;
  
  AudioTelemetry? _lastTelemetry;

  // Pitch tracking stabilization and filtering state
  double _lastPitch = 0.0;
  static const int _medianWindowSize = 3;
  late final PitchRingBuffer _pitchBuffer = PitchRingBuffer(_medianWindowSize);

  AudioProcessorWorker(
    this._uiSendPort,
    Duration updateInterval, {
    this.noiseGateDb = 35.0,
  }) {
    _noiseGateThreshold = math.pow(10.0, (noiseGateDb - 90.0) / 20.0).toDouble();
    _fft = FFT(fftSize);
    
    // Hand our command incoming port back to the UI thread
    _uiSendPort.send(_commandPort.sendPort);

    // Listen for raw float buffer arrays dumped by our platform engines
    _commandPort.listen((dynamic message) {
      if (message is Float32List) {
        _writeToRingBuffer(message);
      } else if (message == "STOP") {
        _shutdown();
      }
    });

    // Start the independent calculations clock loop at your configurable interval
    _ticker = Timer.periodic(updateInterval, (_) => _processCurrentWindow());
  }

  /// Entry point invoked by Isolate.spawn
  static void spawnEntry(AudioProcessorWorkerInput input) {
    AudioProcessorWorker(
      input.uiSendPort,
      input.interval,
      noiseGateDb: input.noiseGateDb,
    );
  }

  /// Thread-safe thread append step for variable chunk packets
  void _writeToRingBuffer(Float32List chunk) {
    for (int i = 0; i < chunk.length; i++) {
      _ringBuffer[_writeIndex] = chunk[i];
      _writeIndex = (_writeIndex + 1) % ringBufferSize;
    }
    _totalSamplesWritten += chunk.length;
  }

  void _processCurrentWindow() {
    // Caveat handling: If we haven't even filled the minimum FFT block yet, bypass
    if (_totalSamplesWritten < fftSize) {
      if (_lastTelemetry != null) _uiSendPort.send(_lastTelemetry);
      return;
    }

    // 1. Extract a sequential linear array window reading backwards from our write index
    final Float32List analysisWindow = Float32List(fftSize);
    int readIndex = (_writeIndex - fftSize + ringBufferSize) % ringBufferSize;
    
    for (int i = 0; i < fftSize; i++) {
      analysisWindow[i] = _ringBuffer[readIndex];
      readIndex = (readIndex + 1) % ringBufferSize;
    }

    // 2. Compute Volume metrics (RMS)
    double sumOfSquares = 0.0;
    for (int i = 0; i < fftSize; i++) {
      final double sample = analysisWindow[i];
      sumOfSquares += sample * sample;
    }
    final double volume = math.sqrt(sumOfSquares / fftSize);

    // 1. Noise gate: Ignore zero-crossing pitch tracker if volume is below the configured threshold
    double rawPitch = 0.0;
    if (volume > _noiseGateThreshold) {
      // Dynamic hysteresis based on signal RMS volume to prevent high-frequency noise chatter
      final double hysteresis = volume * 0.20;
      int zeroCrossings = 0;
      int state = 0; // 1 = positive, -1 = negative

      for (int i = 0; i < fftSize; i++) {
        final double sample = analysisWindow[i];
        if (state == 0) {
          if (sample > hysteresis) {
            state = 1;
          } else if (sample < -hysteresis) {
            state = -1;
          }
        } else if (state == 1) {
          if (sample < -hysteresis) {
            zeroCrossings++;
            state = -1;
          }
        } else if (state == -1) {
          if (sample > hysteresis) {
            zeroCrossings++;
            state = 1;
          }
        }
      }

      rawPitch = (zeroCrossings * 44100) / (2 * fftSize);
      
      // Limit to standard human pitch ranges to reject extreme outlier spikes
      if (rawPitch < 50.0 || rawPitch > 2000.0) {
        rawPitch = 0.0;
      }
    }

    double estimatedPitch = 0.0;
    if (rawPitch > 0.0) {
      // 2. Median filter: eliminate transient pitch spike outliers
      _pitchBuffer.add(rawPitch);
      
      final List<double> values = _pitchBuffer.toList();
      values.sort();
      final double medianPitch = values[values.length ~/ 2];

      // 3. Low-pass filter (Exponential Moving Average) to smooth pitch transition over time
      if (_lastPitch > 0.0) {
        const double alpha = 0.6; // 60% new value, 40% previous value
        estimatedPitch = alpha * medianPitch + (1.0 - alpha) * _lastPitch;
      } else {
        estimatedPitch = medianPitch;
      }
      _lastPitch = estimatedPitch;
    } else {
      // Reset historical filter registers during silence or noise-gated blocks
      _pitchBuffer.clear();
      _lastPitch = 0.0;
    }

    // 3. Compute High-Speed Frequency Analytics via FFTEA
    // FFTEA takes a Float32List and performs optimized Cooley-Tukey transformations
    final fftResult = _fft.realFft(analysisWindow);

    final int outputBins = fftSize ~/ 2;
    final Float32List fftMagnitudes = Float32List(outputBins);

    for (int i = 0; i < outputBins; i++) {
      // Extract the SIMD coordinate pair for this frequency bin
      final Float64x2 coordinate = fftResult[i];

      final double real = coordinate.x;
      final double imag = coordinate.y;

      // Calculate the magnitude (Euclidean distance) natively
      fftMagnitudes[i] = math.sqrt(real * real + imag * imag);
    }
    // 4. Construct telemetry frame envelope and ship back to main isolate
    _lastTelemetry = AudioTelemetry(
      volume: volume,
      estimatedFrequency: estimatedPitch,
      timeDomainSamples: analysisWindow,
      frequencySamples: fftMagnitudes,
    );

    _uiSendPort.send(_lastTelemetry!);
  }

  void _shutdown() {
    _ticker.cancel();
    _commandPort.close();
  }
}