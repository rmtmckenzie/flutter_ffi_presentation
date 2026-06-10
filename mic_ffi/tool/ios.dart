import 'package:ffigen/ffigen.dart';

final config = FfiGenerator(
  headers: Headers(
    entryPoints: [
      Uri.file('src/ios/AudioMarshaller.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioEngine.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioNode.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioFormat.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioSession.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioSessionTypes.h'),
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
      "AVAudioSession",
      "MIDICIProfile",
      "AUParameter",
      "CMAudioFormatDescription",
    }),
  ),
  globals: Globals.includeSet({"AVAudioSessionCategoryRecord", "AVAudioSessionModeDefault"}),
  output: Output(
    dartFile: Uri.file('lib/src/internal/ios_bindings.generated.dart'),
    objectiveCFile: Uri.file('src/ios/generated_bindings.m'),
    style: NativeExternalBindings(assetId: "package:mic_ffi/ios_mic_ffi"),
  ),
);

void main() {
  config.generate();
}
