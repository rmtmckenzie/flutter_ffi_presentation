import 'dart:typed_data';

import 'package:mic_ffi/mic_ffi.dart';

abstract class MicFfi {
  Future<void> startCapture();
  Stream<Float32List> stream();
  Future<void> stopCapture();

  static MicFfi? _engine;

  factory MicFfi() {
    _engine ??= createMicEngine();
    return _engine!;
  }
}
