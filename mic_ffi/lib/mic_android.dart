import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';

import 'package:jni/jni.dart';
import 'package:mic_ffi/interface.dart';
import 'package:mic_ffi/src/internal/android_bindings.generated.dart';

MicFfi createAndroidEngine() {
  return AndroidMicFfi();
}

class AndroidMicFfi implements MicFfi {
  Isolate? _workerIsolate;
  SendPort? _isolateCommandPort;
  ReceivePort? _receivePort;
  StreamSubscription? _portSubscription;
  Future<void>? _spawnFuture;

  double _currentVolume = 0.0;

  @override
  Future<void> startCapture() async {
    if (_workerIsolate != null) return; // Already running
    if (_spawnFuture != null) {
      await _spawnFuture;
      return;
    }

    // 1. Establish the communication port to receive data from the Isolate
    _receivePort = ReceivePort();

    // 2. Listen to incoming volume metrics calculated on the background thread
    _portSubscription = _receivePort!.listen((dynamic message) {
      if (message is SendPort) {
        _isolateCommandPort = message;
      } else if (message is double) {
        _currentVolume = message;
      }
    });

    // 3. Spawn the background isolate and pass it the SendPort
    final spawnCompleter = Completer();

    _spawnFuture = spawnCompleter.future;
    // Spawn using the static method wrapper of our custom worker class
    _workerIsolate = await Isolate.spawn(AndroidMicWorker.spawnEntry, _receivePort!.sendPort);
    spawnCompleter.complete();
    _spawnFuture = null;
  }

  @override
  Future<void> stopCapture() async {
    // if in the middle of spawning wait
    if (_spawnFuture != null) await _spawnFuture;

    _isolateCommandPort?.send("STOP");
    _portSubscription?.cancel();
    _workerIsolate?.kill(priority: Isolate.beforeNextEvent);
    _workerIsolate = null;
    _receivePort = null;
    _currentVolume = 0.0;
  }

  @override
  double get volume => _currentVolume;

  // ----------------------------------------------------------------------
  // THE BACKGROUND ISOLATE WORKER
  // ----------------------------------------------------------------------
  // This top-level or static function runs entirely inside its own thread sandbox.
  static void _isolateMicEntry(SendPort uiSendPort) {
    const sampleRate = 44100;
    const audioFormat = AudioFormat.ENCODING_PCM_16BIT;
    const channelConfig = AudioFormat.CHANNEL_IN_MONO;

    // 1. Query Android for the minimum memory buffer size inside the isolate
    final bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat);

    // 2. Allocate the Direct ByteBuffer out-of-heap memory
    final jniBuffer = JByteBuffer.allocateDirect(bufferSize);

    final rawBytesView = jniBuffer.asUint8List();
    final pcm16SamplesView = Int16List.view(rawBytesView.buffer);

    // 3. Open the Android physical microphone via JNIgen inside this Isolate thread
    final audioRecord = AudioRecord(MediaRecorder$AudioSource.MIC, sampleRate, channelConfig, audioFormat, bufferSize);

    // this fails if we don't have microphone permission, need to handle that properly
    audioRecord.startRecording();

    // 4. Infinite tight loop running completely isolated from the UI thread
    while (true) {
      // Direct high-speed hardware block write from the OS into the memory pool
      audioRecord.read$3(jniBuffer, bufferSize);

      // Perform the high-speed RMS calculation natively in memory
      double volume = _calculateVolumeRMS(pcm16SamplesView, pcm16SamplesView.length);

      // Fire the single double variable back across the isolate port to the UI thread
      uiSendPort.send(volume);
    }
  }

  // Helper inside the isolate to avoid thread hopping dependencies
  static double _calculateVolumeRMS(List<int> buffer, int sampleCount) {
    if (sampleCount <= 0) return 0.0;
    double sumOfSquares = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final double normalizedSample = buffer[i] / 32768.0;
      sumOfSquares += normalizedSample * normalizedSample;
    }
    return math.sqrt(sumOfSquares / sampleCount);
  }
}

class AndroidMicWorker {
  final SendPort _uiSendPort;
  final ReceivePort _commandPort = ReceivePort();

  bool _isRunning = true;
  late final AudioRecord _audioRecord;
  late final JByteBuffer _jniBuffer;
  late final Int16List _pcm16SamplesView;
  late final int _bufferSize;

  AndroidMicWorker(this._uiSendPort);

  /// This is the entry point called by Isolate.spawn
  static void spawnEntry(SendPort uiSendPort) {
    final worker = AndroidMicWorker(uiSendPort);
    worker._initAndRun();
  }

  void _initAndRun() {
    // 1. Hand our local command port mailbox back to the UI thread
    _uiSendPort.send(_commandPort.sendPort);

    // 2. Listen for command messages sent from the UI thread
    _commandPort.listen((dynamic message) {
      if (message == "STOP") {
        _isRunning = false;
      }
    });

    // 3. Setup hardware configurations
    const sampleRate = 44100;
    const audioFormat = AudioFormat.ENCODING_PCM_16BIT;
    const channelConfig = AudioFormat.CHANNEL_IN_MONO;

    _bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat);
    _jniBuffer = JByteBuffer.allocateDirect(_bufferSize);

    final Uint8List rawBytesView = _jniBuffer.asUint8List();
    _pcm16SamplesView = Int16List.view(rawBytesView.buffer);

    _audioRecord = AudioRecord(MediaRecorder$AudioSource.MIC, sampleRate, channelConfig, audioFormat, _bufferSize);

    _audioRecord.startRecording();
    _loop();
  }

  void _loop() async {
    while (_isRunning) {
      _audioRecord.read$3(_jniBuffer, _bufferSize);

      double volume = _calculateVolumeRMS(_pcm16SamplesView);
      _uiSendPort.send(volume);

      // Microscopic breath to allow the commandPort listener to check for "STOP"
      final nextFramePort = ReceivePort();
      Isolate.current.ping(nextFramePort.sendPort);
      await nextFramePort.first;
    }

    _cleanup();
  }

  double _calculateVolumeRMS(Int16List samples) {
    if (samples.isEmpty) return 0.0;
    double sumOfSquares = 0.0;
    for (int i = 0; i < samples.length; i++) {
      final double normalizedSample = samples[i] / 32768.0;
      sumOfSquares += normalizedSample * normalizedSample;
    }
    return sqrt(sumOfSquares / samples.length);
  }

  void _cleanup() {
    _audioRecord.stop();
    _audioRecord.release();
    _commandPort.close();
  }
}
