import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/bullet_list.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

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
    return ListColumn([
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
        "Process Audio bytes in to signals (dart)",
        subItems: [ListItem("volume"), ListItem("pitch"), ListItem("time domain"), ListItem("frequency samples")],
      ),
    ]);
  }
}
