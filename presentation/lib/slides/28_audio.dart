import 'package:audio_process/audio_process.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class AudioAgain extends SlideWidget {
  const AudioAgain({super.key})
      : super(
    configuration: const FlutterDeckSlideConfiguration(
      route: "/audio",
      header: FlutterDeckHeaderConfiguration(title: "FFI Microphone (again)"),
    ),
  );

  @override
  Widget buildBody(BuildContext context) {
    return Center(child: AudioTelemetryView(layout: .grid4x1,));
  }
}
