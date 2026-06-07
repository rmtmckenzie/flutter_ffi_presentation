// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:mic_ffi/interface.dart';

/// A web implementation of the MicFfiPlatform of the MicFfi plugin.
class MicFfiWeb implements MicFfi {
  @override
  Future<void> startCapture() {
    throw UnsupportedError("not implemented"); // TODO: implement startCapture
  }

  @override
  Future<void> stopCapture() {
    throw UnsupportedError("not implemented"); // TODO: implement stopCapture
  }

  @override
  // TODO: implement volume
  double get volume => throw UnimplementedError();
}

MicFfi createMicEngine() {
  return MicFfiWeb();
}
