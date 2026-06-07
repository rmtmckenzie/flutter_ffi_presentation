import 'package:flutter_test/flutter_test.dart';
import 'package:mic_ffi/mic_ffi.dart';
import 'package:mic_ffi/mic_ffi_platform_interface.dart';
import 'package:mic_ffi/mic_ffi_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMicFfiPlatform
    with MockPlatformInterfaceMixin
    implements MicFfiPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MicFfiPlatform initialPlatform = MicFfiPlatform.instance;

  test('$MethodChannelMicFfi is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMicFfi>());
  });

  test('getPlatformVersion', () async {
    MicFfi micFfiPlugin = MicFfi();
    MockMicFfiPlatform fakePlatform = MockMicFfiPlatform();
    MicFfiPlatform.instance = fakePlatform;

    expect(await micFfiPlugin.getPlatformVersion(), '42');
  });
}
