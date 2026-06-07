import 'package:ffigen/ffigen.dart';

final config = FfiGenerator(
  headers: Headers(
    entryPoints: [
      Uri.file('ios/mic_ffi/Sources/mic_ffi_objc/include/AudioMarshaller.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioEngine.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioNode.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioFormat.h'),
    ],
  ),
  objectiveC: ObjectiveC(
    interfaces: Interfaces.includeSet({
      "AudioMarshaller",
      "AVAudioEngine",
      "AVAudioNode",
      "AVAudioInputNode",
      "AVAudioFormat",
      "AVAudioPCMBuffer",
      "MIDICIProfile",
      "AUParameter",
      "CMAudioFormatDescription",
    }),
  ),
  output: Output(
    dartFile: Uri.file('lib/src/internal/ios_bindings.generated.dart'),
    objectiveCFile: Uri.file('ios/mic_ffi/Sources/mic_ffi_objc/bindings.m'),
    // style: NativeExternalBindings(),
    // objectiveCFile: Uri.file('src/ios/generated_bindings.m'),
  ),
);

// final configMarshaller = FfiGenerator(
//   headers: Headers(entryPoints: [Uri.file('src/ios/AudioMarshaller.h')]),
//   objectiveC: ObjectiveC(interfaces: Interfaces.includeSet({'AudioMarshaller'})),
//   output: Output(
//     dartFile: Uri.file('lib/src/internal/ios.generated.dart'),
//     objectiveCFile: Uri.file('src/ios/ios_generated_bindings.m'),
//     style: NativeExternalBindings(
//       assetId: 'package:mic_ffi/mic_ffi',
//     ),
//     // style: DynamicLibraryBindings(
//     //   wrapperName: 'FfiIosLibrary',
//     // ),
//   ),
// );

void main() {
  config.generate();
}
