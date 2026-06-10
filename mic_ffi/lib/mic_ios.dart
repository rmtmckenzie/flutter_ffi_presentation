import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:mic_ffi/interface.dart';
import 'package:mic_ffi/src/internal/ios_bindings.generated.dart';
import 'package:objective_c/objective_c.dart';

MicFfi createIOSEngine() {
  return MicIOS();
}

typedef AudioCallback = ObjCBlock<Void Function(Pointer<Float>, Long)>;

class _Native {
  final AVAudioEngine engine;
  final AudioMarshaller marshaller;
  final AudioCallback callback;

  _Native(this.engine, this.marshaller, this.callback);
}

class MicIOS implements MicFfi {
  _Native? _structures;
  final StreamController<Float32List> _stream = StreamController.broadcast();

  @override
  Future<void> startCapture() async {
    if (_structures != null) {
      return;
    }

    final audioSession = AVAudioSession.sharedInstance();
    audioSession.setCategory$1(
      AVAudioSessionCategoryRecord,
      mode: AVAudioSessionModeDefault,
      options: AVAudioSessionCategoryOptions.AVAudioSessionCategoryOptionMixWithOthers,
    );

    audioSession.setPreferredIOBufferDuration(1024.0/44100.0);

    Activation(audioSession).setActive(true);

    final sampleRate = audioSession.sampleRate;
    final duration = audioSession.IOBufferDuration;
    final actualBufferSize = duration * sampleRate;

    log("Actual buffer size configured to $actualBufferSize");

    // 1. Setup our main-thread Dart destination
    // _dartCallable = NativeCallable<Void Function(Pointer<Float>, Long)>.listener(_processAudioBytes);
    // _dartMainThreadBlock = ObjCBlock_ffiVoid_ffiFloat_NSInteger.fromFunctionPointer(_dartCallable.nativeFunction);

    final dartMainThreadBlock = ObjCBlock_ffiVoid_ffiFloat_NSInteger.blocking(_processAudioBytes);

    // 2. Request a safe native thread-hopping block from our pure helper utility
    // We pass our Dart function reference into Objective-C
    final marshaller = AudioMarshaller.alloc().initWithCallback(dartMainThreadBlock);

    // 3. Build the AVAudioEngine Graph completely in Dart
    final engine = AVAudioEngine.alloc().init();

    _structures = _Native(engine, marshaller, dartMainThreadBlock);

    final inputNode = engine.inputNode;

    final inputFormat = AVAudioFormat.alloc().initStandardFormatWithSampleRate$1(44100.0, channels: 1);

    // 5. Connect the hardware tap block directly inside Dart space
    inputNode.installTapOnBus(0, bufferSize: 1024, format: inputFormat, block: marshaller.getBridgeBlock());
    engine.startAndReturnError();

    return Future.syncValue(null);
  }

  void _processAudioBytes(Pointer<Float> rawFloatBuffer, int frameCount) {

    final Float32List audioSamples = rawFloatBuffer.asTypedList(frameCount);
    // copy the sample to a buffer for safety
    final sampleCopy = Float32List.fromList(audioSamples);
    _stream.add(sampleCopy);
  }

  @override
  Future<void> stopCapture() {
    if (_structures == null) {
      return Future.syncValue(null);
    }

    final structures = _structures!;
    _structures = null;

    structures.engine.inputNode.removeTapOnBus(0);
    structures.engine.stop();
    structures.marshaller.dealloc();
    return Future.syncValue(null);
  }

  @override
  Stream<Float32List> stream() {
    return _stream.stream;
  }
}
