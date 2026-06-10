import 'dart:async';
import 'dart:isolate';
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

  final StreamController<Float32List> _stream = StreamController.broadcast();

  @override
  Future<void> startCapture() async {
    if (_workerIsolate != null) return; // Already running
    if (_spawnFuture != null) {
      await _spawnFuture;
      return;
    }
    _receivePort = ReceivePort();

    _portSubscription = _receivePort!.listen((dynamic message) {
      if (message is SendPort) {
        _isolateCommandPort = message;
      } else if (message is Float32List) {
        _stream.add(message);
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
  }

  @override
  Stream<Float32List> stream() {
    // TODO: implement stream
    throw UnimplementedError();
  }

}

class AndroidMicWorker {
  final SendPort _uiSendPort;
  final ReceivePort _commandPort = ReceivePort();

  bool _isRunning = true;
  late final AudioRecord _audioRecord;
  late final JByteBuffer _jniBuffer;
  late final Float32List _pcmSamplesView;
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
    const audioFormat = AudioFormat.ENCODING_PCM_FLOAT;
    const channelConfig = AudioFormat.CHANNEL_IN_MONO;

    _bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat);
    _jniBuffer = JByteBuffer.allocateDirect(_bufferSize);

    final Uint8List rawBytesView = _jniBuffer.asUint8List();
    _pcmSamplesView = Float32List.view(rawBytesView.buffer);

    _audioRecord = AudioRecord(MediaRecorder$AudioSource.MIC, sampleRate, channelConfig, audioFormat, _bufferSize);

    _audioRecord.startRecording();
    _loop();
  }

  void _loop() async {
    while (_isRunning) {
      _audioRecord.read$3(_jniBuffer, _bufferSize);

      // copy to dart memory
      final copy = Float32List.fromList(_pcmSamplesView);
      _uiSendPort.send(copy.asUnmodifiableView());

      // Microscopic breath to allow the commandPort listener to check for "STOP"
      final nextFramePort = ReceivePort();
      Isolate.current.ping(nextFramePort.sendPort);
      await nextFramePort.first;
    }

    _cleanup();
  }

  void _cleanup() {
    _audioRecord.stop();
    _audioRecord.release();
    _commandPort.close();
  }
}
