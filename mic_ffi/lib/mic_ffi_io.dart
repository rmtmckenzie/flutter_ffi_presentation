

import 'dart:io';

import 'package:mic_ffi/interface.dart';

import 'mic_android.dart';
import 'mic_ffi_desktop.dart';
import 'mic_ios.dart';

MicFfi createMicEngine() {
  // Standard platform switches are fine here because they only run ONCE during initialization,
  // acting as an isolated router rather than cluttering your UI code.
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) return DesktopMicEngine();
  if (Platform.isAndroid) return createAndroidEngine();
  if (Platform.isIOS) return createIOSEngine();
  throw UnsupportedError("Unsupported platform ${Platform.operatingSystem}");
}