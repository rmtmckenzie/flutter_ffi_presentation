import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/signing.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class EncAgain extends SlideWidget {
  const EncAgain({super.key})
      : super(
    configuration: const FlutterDeckSlideConfiguration(
        route: "/monocypher-again",
      header: FlutterDeckHeaderConfiguration(title: "Monocypher (again)"),
    ),
  );

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: Signing(),
    );
  }
}