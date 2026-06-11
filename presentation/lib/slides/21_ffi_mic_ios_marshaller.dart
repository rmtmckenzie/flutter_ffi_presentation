import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

const tap = """
inputNode.installTapOnBus(
  0, bufferSize: 1024, 
  format: inputFormat, 
  block: marshaller.getBridgeBlock()
);""";

const marshaller = """
#ifndef AudioMarshaller_h
#define AudioMarshaller_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// The final main-thread Dart destination block signature
typedef void (^DartMainThreadCallback)(float * _Nonnull rawSamples, NSInteger frameCount);

// The hardware block signature that AVAudioEngine expects
typedef void (^AVAudioEngineTapBlock)(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when);

@interface AudioMarshaller : NSObject

// Instantiate the marshaller by passing the Dart callback directly to the initializer
- (instancetype _Nonnull)initWithCallback:(DartMainThreadCallback _Nonnull)dartCallback;

// Request a safe native thread-hopping block tied to this instance
- (AVAudioEngineTapBlock _Nonnull)getBridgeBlock;

@end

#endif /* AudioMarshaller_h */
""";

const marshallerC = """
return ^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
    AudioMarshaller *strongSelf = weakSelf;
    if (strongSelf == nil || buffer.floatChannelData == NULL || buffer.frameLength == 0) return;

    float *channelData = buffer.floatChannelData[0];
    NSInteger frameCount = (NSInteger)buffer.frameLength;

    // Duplicate the memory immediately on the background thread
    float *copiedPointer = (float *)malloc(frameCount * sizeof(float));
    if (copiedPointer == NULL) return;
    memcpy(copiedPointer, channelData, frameCount * sizeof(float));

    dispatch_async(dispatch_get_main_queue(), ^{
        // 3. Safely invoke Dart on the Main UI thread isolate
        if (strongSelf->_boundDartCallback != nil) {
            strongSelf->_boundDartCallback(copiedPointer, frameCount);
        }
        free(copiedPointer);
    });
};
""";

const ffigen = r"""
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
""";

const buildDart = """
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
""";

class FFIMicIOSMarshaller extends SlideWidget {
  const FFIMicIOSMarshaller({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/ffi-mic-ios-marshaller",
          steps: 5,
          header: FlutterDeckHeaderConfiguration(title: "FFI Microphone - Marshaller"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: ListColumn([
            ListItem(
              "Objective-c Code Needed",
              subItems: [
                ListItem("Accepts dart callback"),
                ListItem("Uses GCD to swap to Main Thread", subItems: [ListItem("Copies memory from audio buffers")]),
              ],
            ),
            ListItem(
              "Compilation from source",
              subItems: [ListItem(r"-fobjc-arc"), ListItem("-ObjC"), ListItem("specify objective-c")],
            ),
          ]),
        ),
        Expanded(
          flex: 10,
          child: Center(
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, step) {
                switch (step) {
                  case 1:
                    return FlutterDeckCodeHighlight(code: tap, textStyle: TextStyle(fontSize: 25));
                  case 2:
                    return FlutterDeckCodeHighlight(
                      code: marshaller,
                      language: 'dart',
                      fileName: "AudioMarshaller.h",
                      textStyle: TextStyle(fontSize: 15),
                    );
                  case 3:
                    return FlutterDeckCodeHighlight(
                      code: marshallerC,
                      language: 'dart',
                      fileName: "AudioMarshaller.m",
                      textStyle: TextStyle(fontSize: 15),
                    );
                  case 4:
                    return FlutterDeckCodeHighlight(
                      code: ffigen,
                      language: 'dart',
                      fileName: "ffigen.dart",
                      textStyle: TextStyle(fontSize: 12),
                      highlightedLines: [5, 16],
                    );
                  case 5:
                    return FlutterDeckCodeHighlight(
                      code: buildDart,
                      language: 'dart',
                      textStyle: TextStyle(fontSize: 15),
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
