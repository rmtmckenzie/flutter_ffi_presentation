import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mic_ffi/mic_ffi.dart';
import 'package:mic_ffi/src/internal/bindings.generated.dart';
import 'package:mic_ffi/temp.dart';

class DesktopMicEngine implements MicFfi {
  final StreamController<double> _stream = StreamController.broadcast();
  double _currentVolume = 0;

  Pointer<ma_device>? _device;

  // This runs safely on your Dart UI event loop!
  // note that there is a _slight_ delay here due to it being
  // passed to the event loop - it could be slightly faster to
  // do the calculations in the c side of things.
  void _dartAudioCallback(Pointer<ma_device> pDevice, Pointer<Void> pOutput, Pointer<Void> pInput, int frameCount) {
    if (pInput == nullptr) return;

    // Cast raw pointer to extract your float array data
    final Pointer<Float> samples = pInput.cast<Float>();
    // if we want to copy these out, make sure to copy safely
    //
    // (Since channels = 1, total samples = frameCount * 1)
    //final Float32List audioSamples = sampleBuffer.asTypedList(frameCount);
    // final sampleCopy = Float32List.fromList(audioSamples);

    final volume = calculateFloatRMS(samples, frameCount);

    _currentVolume = volume;
    _stream.add(volume);
  }

  @override
  Future<void> startCapture() {
    // 1. Create a thread-safe NativeCallable listener callback
    final NativeCallable<ma_device_data_procFunction> micCallable =
        NativeCallable<ma_device_data_procFunction>.listener(_dartAudioCallback);

    // 2. Initialize the struct by value on the Dart stack
    ma_device_config config = ma_device_config_init(ma_device_type_capture);

    // 3. Configure the local stack struct
    config.capture.format = ma_format_f32;
    config.capture.channels = 1;
    config.sampleRate = 44100;
    config.dataCallback = micCallable.nativeFunction;

    // 4. Allocate long-lived native memory for both the config and the device
    final configPtr = calloc<ma_device_config>();
    final devicePtr = calloc<ma_device>();

    try {
      // 5. Copy the stack struct into the heap-allocated memory
      configPtr.ref = config;

      // 6. Pass the safe heap pointer to ma_device_init
      ma_device_init(nullptr, configPtr, devicePtr);
      ma_device_start(devicePtr);
      _device = devicePtr;
    } finally {
      // 7. Clean up the config pointer since miniaudio copies this data internally
      // Note: Do NOT free devicePtr here, as the device needs to live on!
      calloc.free(configPtr);
    }

    return Future.syncValue(null);
  }

  bool get capturing {
    return _device != null;
  }

  @override
  double get volume => _currentVolume;

  Stream<double> stream() => _stream.stream;

  @override
  Future<void> stopCapture() {
    final device = _device;
    if (device == null || device == nullptr) {
      return Future.syncValue(null);
    }
    // 1. Stop the audio hardware thread from capturing samples
    ma_device_stop(device);

    // 2. Uninitialize the device internals (closes OS audio streams, frees internal ring buffers)
    ma_device_uninit(device);

    // 3. Free the C-heap memory allocated for the struct itself
    calloc.free(device);

    _device = null;
    _currentVolume= 0;

    return Future.syncValue(null);
  }
}
