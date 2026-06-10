import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:mic_ffi/mic_ffi.dart';
import 'package:mic_ffi/src/internal/bindings.generated.dart';

class DesktopMicEngine implements MicFfi {
  final StreamController<Float32List> _stream = StreamController.broadcast();
  Pointer<ma_device>? _device;

  // This runs safely on your Dart UI event loop!
  // note that there is a _slight_ delay here due to it being
  // passed to the event loop
  void _dartAudioCallback(Pointer<ma_device> pDevice, Pointer<Void> pOutput, Pointer<Void> pInput, int frameCount) {
    if (pInput == nullptr) return;

    final Pointer<Float> samples = pInput.cast<Float>();

    final Float32List audioSamples = samples.asTypedList(frameCount);
    // copy the sample to a buffer for safety
    final sampleCopy = Float32List.fromList(audioSamples);

    _stream.add(sampleCopy);
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
  Stream<Float32List> stream() => _stream.stream;

  @override
  Future<void> stopCapture() {
    final device = _device;
    if (device == null || device == nullptr) {
      return Future.syncValue(null);
    }
    ma_device_stop(device);
    ma_device_uninit(device);
    calloc.free(device);

    _device = null;
    return Future.syncValue(null);
  }
}
