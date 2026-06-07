// 1. Define the platform-agnostic interface
import 'dart:io';

import 'package:mic_ffi/mic_ffi.dart';

abstract class MicFfi {
  Future<void> startCapture();
  double get volume;
  Future<void> stopCapture();

  static MicFfi? _engine;

  // 2. The magic factory constructor
  factory MicFfi() {
    if (_engine == null) {
      _engine = createMicEngine();
    }
    return _engine!;
  }
}
