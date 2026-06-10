import 'dart:developer';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

class WhoSlide extends SlideWidget {
  const WhoSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/who",
          header: FlutterDeckHeaderConfiguration(title: "Who is FFI?"),
          steps: 2,
        ),
      );

  @override
  Widget buildHeader(BuildContext context) {
    return FlutterDeckSlideStepsBuilder(
      builder: (context, stepNumber) {
        final headerTheme = FlutterDeckHeaderTheme.of(context);
        switch (stepNumber) {
          case 1:
            log("Making without crossthrough");
            return super.buildHeader(context);
          case 2:
          default:
            log("Making with crossthrough");
            return FlutterDeckHeaderTheme(
              data: headerTheme.copyWith(textStyle: headerTheme.textStyle?.copyWith(decoration: .lineThrough)),
              child: Builder(
                builder: (context) {
                  return super.buildHeader(context);
                },
              ),
            );
        }
      },
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return TitleRowFlex(
      titleFlex: 1,
      bodyFlex: 3,
      child: Column(
        spacing: 20,
        children: [TitleRow(title: "", body: AutoSizeText(""))],
      ),
    );
  }
}
