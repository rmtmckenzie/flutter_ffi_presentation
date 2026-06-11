import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

const code = """
abstract class MicFfi {
  Future<void> startCapture();
  Stream<Float32List> stream();
  Future<void> stopCapture();

  static MicFfi? _engine;

  factory MicFfi() {
    _engine ??= createMicEngine();
    return _engine!;
  }
}
""";

class FfiMic extends SlideWidget {
  const FfiMic({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/ffi-mic",
          header: FlutterDeckHeaderConfiguration(title: "FFI Microphone - Project"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListColumn([
            ListItem(
              "Input from Microphone (FFI)",
              subItems: [
                ListItem("iOS - AVFoundation"),
                ListItem("Android - AudioRecord, MediaRecorder"),
                ListItem("Desktop Platforms - MiniAudio"),
                ListItem("Web - AudioContext, MediaStream"),
              ],
            ),
            ListItem(
              "Capture Audio bytes to stream",
              subItems: [ListItem("volume"), ListItem("pitch"), ListItem("time domain"), ListItem("frequency samples")],
            ),
          ]),
        ),
        Expanded(
          child: FlutterDeckCodeHighlight(
            code: code,
          ),
        )
      ],
    );
  }
}
