import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

const tool = r"""
import 'package:ffigen/ffigen.dart';

final config = FfiGenerator(
  headers: Headers(
    entryPoints: [
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioEngine.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioNode.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioFormat.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioSession.h'),
      Uri.file('$iosSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioSessionTypes.h'),
    ],
  ),
  objectiveC: ObjectiveC(
    interfaces: Interfaces.includeSet({
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
""";

const code = r"""
  final audioSession = AVAudioSession.sharedInstance();
  audioSession.setCategory$1(
    AVAudioSessionCategoryRecord,
    mode: AVAudioSessionModeDefault,
    options: AVAudioSessionCategoryOptions
      .AVAudioSessionCategoryOptionMixWithOthers,
  );

  audioSession.setPreferredIOBufferDuration(1024.0/44100.0);

  Activation(audioSession).setActive(true);

  final engine = AVAudioEngine.alloc().init();

  _structures = _Native(engine, marshaller, dartMainThreadBlock);

  final inputNode = engine.inputNode;

  final inputFormat = AVAudioFormat.alloc()
    .initStandardFormatWithSampleRate$1(44100.0, channels: 1);

  inputNode.installTapOnBus(
    0, bufferSize: 1024, 
    format: inputFormat, 
    block: marshaller.getBridgeBlock()
  );
  engine.startAndReturnError();
""";

const marshaller = """
inputNode.installTapOnBus(
  0, bufferSize: 1024, 
  format: inputFormat, 
  block: marshaller.getBridgeBlock()
);""";

class FFIMicIOS extends SlideWidget {
  const FFIMicIOS({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/ffi-mic-ios",
          steps: 5,
          header: FlutterDeckHeaderConfiguration(title: "FFI Microphone - iOS"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: FlutterDeckSlideStepsBuilder(
            builder: (context, step) {
              return ListColumn([
                ListItem(
                  "tool/ios.dart",
                  subItems: [
                    ListItem("use FFIGen"),
                    ListItem(
                      "generate bindings for AVFoundation",
                      subItems: step < 5 ? [ListItem("AVEngine"), ListItem("AVAudioNode"), ListItem("etc...")] : [],
                    ),
                  ],
                ),
                ListItem("Call APIs Directly", subItems: step > 3 ? [ListItem("what's that marshaller thing?")] : []),
                if (step > 4)
                  ListItem("ARGH SWEAR ANGER", subItems: [
                    ListItem("Have to be very careful on iOS", subItems: [
                      ListItem("especially audio =("),
                      ListItem("frames back on different thread"),
                      ListItem("engine complains and errors")
                    ])
                  ])
              ]);
            },
          ),
        ),
        Expanded(
          flex: 10,
          child: Center(
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, step) {
                switch (step) {
                  case 2:
                    return FlutterDeckCodeHighlight(
                      code: tool,
                      language: 'dart',
                      fileName: "ios.dart",
                      textStyle: TextStyle(fontSize: 12),
                    );
                  case 3:
                    return FlutterDeckCodeHighlight(
                      code: code,
                      language: 'dart',
                      fileName: "isolate.dart",
                      textStyle: TextStyle(fontSize: 15),
                    );
                  case 4:
                  case 5:
                    return FlutterDeckCodeHighlight(
                      code: marshaller,
                      language: 'dart',
                      textStyle: TextStyle(fontSize: 25),
                    );
                  default:
                    return SizedBox();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
