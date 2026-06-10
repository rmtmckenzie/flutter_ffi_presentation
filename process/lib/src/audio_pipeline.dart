import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_process/src/audio_processor_worker.dart';
import 'package:audio_process/src/audio_telemetry.dart';

class AudioPipeline {
  Isolate? _processorIsolate;
  ReceivePort? _uiReceivePort;
  StreamSubscription? _subscription;
  SendPort? _processorCommandPort;

  // Stream controller allows UI widgets or CustomPainters to listen smoothly
  final StreamController<AudioTelemetry> _telemetryStreamController = StreamController<AudioTelemetry>.broadcast();

  Stream<AudioTelemetry> get telemetryStream => _telemetryStreamController.stream;

  /// Starts the processing pipeline with a highly configurable update tick interval rate
  Future<void> initialize({
    Duration updateInterval = const Duration(milliseconds: 100),
    double noiseGateDb = 35.0,
    void Function(AudioProcessorWorkerInput input) spawnEntry = AudioProcessorWorker.spawnEntry,
  }) async {
    _uiReceivePort = ReceivePort();

    _subscription = _uiReceivePort!.listen((dynamic message) {
      if (message is SendPort) {
        _processorCommandPort = message;
      } else if (message is AudioTelemetry) {
        _telemetryStreamController.add(message);
      }
    });

    _processorIsolate = await Isolate.spawn(
      spawnEntry,
      AudioProcessorWorkerInput(_uiReceivePort!.sendPort, updateInterval, noiseGateDb: noiseGateDb),
    );
  }

  /// Forward incoming platform mic buffers directly to the isolated processor pipeline
  void feedRawBuffer(Float32List rawBuffer) {
    _processorCommandPort?.send(rawBuffer.asUnmodifiableView());
  }

  void dispose() {
    _processorCommandPort?.send("STOP");
    _subscription?.cancel();
    _uiReceivePort?.close();
    _processorIsolate?.kill(priority: Isolate.beforeNextEvent);

    _processorIsolate = null;
    _processorCommandPort = null;
  }
}
