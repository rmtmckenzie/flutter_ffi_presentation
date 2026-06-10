import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/default_text.dart';
import 'package:flutter_ffi_presentation/components/helpers.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class WhatIsFfi extends SlideWidget {
  const WhatIsFfi({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/what-is-ffi",
          header: FlutterDeckHeaderConfiguration(title: "What is FFI?"),
          preloadImages: {"assets/6/diagram_dark.png", "assets/6/diagram_light.png"},
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    final bright = context.theme.brightness;
    return Row(
      spacing: 20,
      children: [
        Expanded(
          child: DefaultTextFunc(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 10,
              children: [
                AutoSizeText("Fast Foreign Interface"),
                AutoSizeText("Originally from LISP"),
                AutoSizeText("JNI, Python CFFI"),
              ],
            ),
          ),
        ),
        Expanded(child: Image.asset("assets/what/${bright.name}.png")),
      ],
    );
  }
}
