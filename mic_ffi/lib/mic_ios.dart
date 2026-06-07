// import 'dart:ffi';
// import 'dart:math';
//
// import 'package:mic_ffi/interface.dart';
// import 'package:mic_ffi/src/internal/ios_bindings.generated.dart';
// import 'package:objective_c/objective_c.dart';
//

// class IOSMicEngine implements MicFfi {
//   IOSMicWorker? _worker;
//   double _currentVolume = 0.0;
//
//   @override
//   Future<void> startCapture() {
//     if (_worker != null) return Future.syncValue(null);
//
//     // Initialize the worker and supply it with a direct state update callback
//     _worker = IOSMicWorker(
//       onVolumeCalculated: (double volume) {
//         _currentVolume = volume; // Safely runs on the main thread UI event loop
//       },
//     );
//
//     _worker!.start();
//
//     return Future.syncValue(null);
//   }
//
//   @override
//   double get volume {
//     // Flutter UI thread synchronously polls this instantly
//     return _currentVolume;
//   }
//
//   @override
//   Future<void> stopCapture() {
//     _worker?.stop();
//     _worker = null;
//     _currentVolume = 0.0;
//
//     return Future.syncValue(null);
//   }
// }
//
// class IOSMicWorker {
//   final void Function(double) _onVolumeCalculated;
//
//   late final AVAudioEngine _engine;
//   late final AudioMarshaller _marshaller; // Instantiated from pure ObjC bindings!
//   bool _isRecording = false;
//
//   // keep these around as long as we're recording.
//   late final NativeCallable<Void Function(Pointer<ObjCObjectImpl>, Pointer<ObjCObjectImpl>)> _audioTapCallable;
//   late final ObjCBlock<Void Function(AVAudioPCMBuffer, AVAudioTime)> _audioTapBlock;
//   late final NativeCallable<Void Function(Pointer<Float>, Int)> _dartCallable;
//   late final ObjCBlock<Void Function(Pointer<Float>, Int)> _dartMainThreadBlock;
//   // late final ObjCBlock_ffiVoid_objcObjCObjectImpl_objcObjCObjectImpl _hardwareTapBlock;
//
//
//   IOSMicWorker({required this._onVolumeCalculated});
//
//   void start() {
//     if (_isRecording) return;
//
//     // 1. Initialize the thread-safe NativeCallable listener
//     _audioTapCallable = NativeCallable<Void Function(Pointer<ObjCObjectImpl>, Pointer<ObjCObjectImpl>)>.listener(
//       _handleAudioBuffer,
//     );
//
//     // 2. Instantiate Apple's native audio engine structures
//     _engine = AVAudioEngine.alloc().init();
//     final inputNode = _engine.inputNode;
//     // final inputFormat = inputNode.inputFormatForBus(0);
//     final inputFormat = AVAudioFormat.alloc().initStandardFormatWithSampleRate$1(
//       44100.0,
//       channels: 1,
//     );
//
//     _audioTapBlock = ObjCBlock_ffiVoid_AVAudioPCMBuffer_AVAudioTime.fromFunctionPointer(
//       _audioTapCallable.nativeFunction,
//     );
//
//     // 3. Install the real-time audio tap using our safe function pointer
//     inputNode.installTapOnBus(
//       0,
//       bufferSize: 1024, // Pull chunks of 1024 frames
//       format: inputFormat,
//       block: _audioTapBlock,
//     );
//
//     // 4. Fire up the physical hardware stream
//     try {
//       _engine.startAndReturnError();
//     } catch(e) {
//       print("ERROR LISTENINT TO MIC: $e");
//       rethrow;
//     }
//     _isRecording = true;
//   }
//
//   // ----------------------------------------------------------------------
//   // THE BACKGROUND HARDWARE CALLBACK
//   // ----------------------------------------------------------------------
//   // This specific code is invoked live by macOS/iOS CoreAudio threads!
//   void _handleAudioBuffer(Pointer<ObjCObjectImpl> bufferObj, Pointer<ObjCObjectImpl> whenObj) {
//     // Cast the generic pointer back to a type-safe AVAudioPCMBuffer wrapper
//     final pcmBuffer = AVAudioPCMBuffer.fromPointer(bufferObj);
//
//     // Extract the raw floating-point memory channels (0ms data copying cost)
//     final Pointer<Pointer<Float>> floatChannelData = pcmBuffer.floatChannelData;
//     final Pointer<Float> rawSamples = floatChannelData.value;
//
//     // Perform high-speed decimal RMS calculation
//     double volume = _calculateFloatRMS(rawSamples, 1024);
//
//     // Forward the simple primitive metric directly back to the UI thread listener
//     _onVolumeCalculated(volume);
//   }
//
//   double _calculateFloatRMS(Pointer<Float> buffer, int sampleCount) {
//     if (sampleCount <= 0) return 0.0;
//     double sumOfSquares = 0.0;
//     for (int i = 0; i < sampleCount; i++) {
//       final double sample = buffer[i];
//       sumOfSquares += sample * sample;
//     }
//     return sqrt(sumOfSquares / sampleCount);
//   }
//
//   void stop() {
//     if (!_isRecording) return;
//
//     _engine.inputNode.removeTapOnBus(0);
//     _engine.stop();
//     _audioTapCallable.close(); // Clean up the native function pointer allocation
//     _audioTapBlock.ref.release();
//     _isRecording = false;
//   }
// }

import 'dart:developer';
import 'dart:ffi';
import 'dart:math' as math;

import 'package:mic_ffi/interface.dart';
import 'package:mic_ffi/src/internal/ios_bindings.generated.dart';
import 'package:objective_c/objective_c.dart';

MicFfi createIOSEngine() {
  return MicIOS();
}

class MicIOS implements MicFfi {
  late final AVAudioEngine _engine;
  late final AudioMarshaller _marshaller; // Instantiated from pure ObjC bindings!

  late final NativeCallable<Void Function(Pointer<Float>, Long)> _dartCallable;
  late final ObjCBlock<Void Function(Pointer<Float>, Long)> _dartMainThreadBlock;

  double _currentVolume = 0.0;

  @override
  Future<void> startCapture() async {
    // NativeLibrary.open('package:mic_ffi/mic_ffi');
    // print("OPENING MIC_FFI FRAMEWORK");
    // DynamicLibrary.open('Frameworks/mic_ffi.framework/mic_ffi');
    // print("OPENED MIC_FFI FRAMEWORK");

    // await Future.delayed(Duration(seconds: 1));

    log("STARTING");

    // 1. Setup our main-thread Dart destination
    // _dartCallable = NativeCallable<Void Function(Pointer<Float>, Long)>.listener(_processAudioBytes);
    // _dartMainThreadBlock = ObjCBlock_ffiVoid_ffiFloat_NSInteger.fromFunctionPointer(_dartCallable.nativeFunction);

    _dartMainThreadBlock = ObjCBlock_ffiVoid_ffiFloat_NSInteger.blocking(_processAudioBytes);


    // 2. Request a safe native thread-hopping block from our pure helper utility
    // We pass our Dart function reference into Objective-C
    _marshaller = AudioMarshaller.alloc().initWithCallback(_dartMainThreadBlock);

    // 3. Build the AVAudioEngine Graph completely in Dart
    _engine = AVAudioEngine.alloc().init();
    final inputNode = _engine.inputNode;

    final inputFormat = AVAudioFormat.alloc().initStandardFormatWithSampleRate$1(44100.0, channels: 1);

    // 5. Connect the hardware tap block directly inside Dart space
    inputNode.installTapOnBus(
      0,
      bufferSize: 1024,
      format: inputFormat,
      block: _marshaller.getBridgeBlock(),
    );
    // inputNode.installTapOnBus_bufferSize_format_block_(0, 1024, inputFormat, _hardwareTapBlock);
    _engine.startAndReturnError();

    return Future.syncValue(null);
  }

  void _processAudioBytes(Pointer<Float> rawFloatBuffer, int frameCount) {
    double sumOfSquares = 0.0;
    for (int i = 0; i < frameCount; i++) {
      sumOfSquares += rawFloatBuffer[i] * rawFloatBuffer[i];
    }
    _currentVolume = math.sqrt(sumOfSquares / frameCount);
  }

  @override
  double get volume => _currentVolume;

  @override
  Future<void> stopCapture() {
    _engine.inputNode.removeTapOnBus(0);
    _engine.stop();
    _dartCallable.close();
    _currentVolume = 0.0;
    _marshaller.dealloc();

    return Future.syncValue(null);
  }
}
