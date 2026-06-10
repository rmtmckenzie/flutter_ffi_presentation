import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/default_text.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

import '../components/helpers.dart';

class WhatIsFfiNow extends SlideWidget {
  const WhatIsFfiNow({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/what-is-ffi-now",
          steps: 3,
          header: FlutterDeckHeaderConfiguration(title: "What is FFI (Now)"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    final bright = context.theme.brightness;
    return DefaultTextFunc(
      child: FlutterDeckSlideStepsBuilder(
        builder: (context, steps) {
          return Row(
            spacing: 20,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    Column(
                      spacing: 20,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: AutoSizeText("Build Hooks to Compile Code", textAlign: TextAlign.start),
                        ),
                        Image.asset("assets/whatnow/lib_${bright.name}.png", height: 300),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 10,
                child: Visibility(
                  visible: steps > 1,
                  child: Column(
                    spacing: 50,
                    children: [
                      Column(
                        spacing: 20,
                        children: [
                          AutoSizeText("Automatic Bundling"),
                          Image.asset("assets/whatnow/embed_${bright.name}.png"),
                        ],
                      ),
                      Visibility(
                        visible: steps > 2,
                        child: Column(
                          spacing: 20,
                          children: [
                            AutoSizeText("Code Inference +Code Generation"),
                            Image.asset("assets/whatnow/dart-code-file-icon.png", height: 150),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
