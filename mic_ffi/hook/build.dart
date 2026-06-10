// ignore_for_file: avoid_print

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // without this sometimes get error accessing
    // input.config.code.targetOS
    if (!input.config.buildCodeAssets) {
      print("Invoked for non-code build assets");
      return;
    }

    final targetOS = input.config.code.targetOS;
    final packageName = input.packageName;

    // Bail out gracefully if compiling for Android as we are
    // only using system libraries
    // Web is not currently supported, so don't need to handle it.
    if (targetOS == OS.android) {
      // Do nothing! Let the native build gradle handle.
      return;
    } else if (targetOS == OS.iOS) {
      final cBuilder = CBuilder.library(
        name: packageName,
        assetName: 'ios_mic_ffi',
        sources: ['src/ios/AudioMarshaller.m', 'src/ios/generated_bindings.m'],
        frameworks: ['Foundation', 'AVFoundation'],
        flags: ['-fobjc-arc', '-ObjC'],
        language: .objectiveC,
      );

      await cBuilder.run(input: input, output: output);
      return;
    } else {
      // for desktop
      final cBuilder = CBuilder.library(
        name: packageName,
        assetName: 'src/internal/bindings.generated.dart',
        sources: ['src/miniaudio/miniaudio.c'],
      );

      await cBuilder.run(input: input, output: output);
    }
  });
}
