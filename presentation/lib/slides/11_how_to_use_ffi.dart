import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/bullet_list.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class HowUseFfi extends SlideWidget {
  const HowUseFfi({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/how-use-ffi",
          header: FlutterDeckHeaderConfiguration(title: "How to use FFI - Monocypher"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return ListColumn([
      ListItem(
        "Fairly basic setup",
        subItems: [ListItem("Single C file to compile"), ListItem("Compiles easily on every platform"), ListItem("No external dependencies")],
      ),
      ListItem("Cryptography",
      subItems: [ListItem("Signing"), ListItem("Encryption"), ListItem("etc...")])
    ]);
  }
}
