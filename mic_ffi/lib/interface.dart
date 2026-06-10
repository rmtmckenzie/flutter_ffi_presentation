// 1. Define the platform-agnostic interface
import 'dart:typed_data';

import 'package:mic_ffi/mic_ffi.dart';

abstract class MicFfi {
  Future<void> startCapture();
  Stream<Float32List> stream();
  Future<void> stopCapture();

  static MicFfi? _engine;

  // 2. The magic factory constructor
  factory MicFfi() {
    _engine ??= createMicEngine();
    return _engine!;
  }
}
