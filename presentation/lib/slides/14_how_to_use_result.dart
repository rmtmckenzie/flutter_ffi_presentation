import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/signing.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class HowToUseResult extends SlideWidget {
  const HowToUseResult({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/how-to-use-result",
          header: FlutterDeckHeaderConfiguration(title: "How To: Monocypher - Result"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: Signing(),
    );
  }
}
