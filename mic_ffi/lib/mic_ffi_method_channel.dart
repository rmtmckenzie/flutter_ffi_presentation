import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mic_ffi_platform_interface.dart';

/// An implementation of [MicFfiPlatform] that uses method channels.
class MethodChannelMicFfi extends MicFfiPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mic_ffi');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
