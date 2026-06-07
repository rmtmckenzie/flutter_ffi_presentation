import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {

    // can only handle building code assets
    if (!input.config.buildCodeAssets) {
      print("Invoked for non-code build assets");
      return;
    }

    final targetOS = input.config.code.targetOS;
    final packageName = input.packageName;

    // Bail out gracefully if compiling for Android
    // Web is not currently supported, so don't need to handle it.
    if (targetOS == OS.android) {
      // Do nothing! Let the native build gradle handle.
      return;
    } else if (targetOS == OS.iOS) {
      print("COMPILING FOR IOS!!!!");
      // throw("TESTING THAT IT FAILS");
      // we need to compile the extra files to make things work for ios
      final cBuilder = CBuilder.library(
        name: packageName,
        assetName: 'src/internal/ios.generated.dart',
        sources: ['src/ios/AudioMarshaller.m', 'src/ios/generated_bindings.m'],
        frameworks: ['Foundation', 'AVFoundation'],
        flags: ['-fobjc-arc', '-ObjC'],
        language: .objectiveC
      );

      await cBuilder.run(
        input: input,
        output: output,
        logger: Logger('')
          ..level = .ALL
          ..onRecord.listen((record) => print(record.message)),
      );

      print("DONE COMPILING FOR IOS!!");

    } else {
      // for desktop
      final cBuilder = CBuilder.library(
        name: packageName,
        assetName: 'src/internal/bindings.generated.dart',
        sources: ['src/miniaudio/miniaudio.c'],
      );

      await cBuilder.run(
        input: input,
        output: output,
        logger: Logger('')
          ..level = .ALL
          ..onRecord.listen((record) => print(record.message)),
      );
    }
  });
}
