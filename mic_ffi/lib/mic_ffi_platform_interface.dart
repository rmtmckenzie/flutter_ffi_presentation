import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mic_ffi_method_channel.dart';

abstract class MicFfiPlatform extends PlatformInterface {
  /// Constructs a MicFfiPlatform.
  MicFfiPlatform() : super(token: _token);

  static final Object _token = Object();

  static MicFfiPlatform _instance = MethodChannelMicFfi();

  /// The default instance of [MicFfiPlatform] to use.
  ///
  /// Defaults to [MethodChannelMicFfi].
  static MicFfiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MicFfiPlatform] when
  /// they register themselves.
  static set instance(MicFfiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
