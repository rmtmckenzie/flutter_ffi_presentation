import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/helpers.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

class HowUsedToWorkSlide extends SlideWidget {
  const HowUsedToWorkSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/how-plugins-work",
          header: FlutterDeckHeaderConfiguration(title: "Who is FFI?"),
          title: "How Plugins (used to) work",
          steps: 4,
          speakerNotes: """
V1: Message channels:
  - encoded by flutter engine
  - very basic
  - error prone
  - asynchronous
V2: Pigeon
  - takes some of the translation pane away
  - still need per-platform code, encoding, etc
V3: Manual FFI
  - needed to compile code yourself
  - dynamic loading handling in code
  - write all functions, hope you don't mess up types
""",
        ),
      );

  @override
  Widget buildHeader(BuildContext context) {
    final headerTheme = FlutterDeckHeaderTheme.of(context);

    return FlutterDeckHeaderTheme(
      data: headerTheme.copyWith(textStyle: headerTheme.textStyle?.copyWith(decoration: .lineThrough)),
      child: Builder(
        builder: (context) {
          return super.buildHeader(context);
        },
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    final textTheme = context.textTheme;
    return TitleRowFlex(
      titleFlex: 1,
      bodyFlex: 3,
      child: FlutterDeckSlideStepsBuilder(
        builder: (context, step) {
          return Column(
            crossAxisAlignment: .start,
            spacing: 20,
            children: [
              AutoSizeText("How Plugins (used) to work", style: textTheme.displayLarge, textAlign: TextAlign.start),
              SizedBox(),
              TitleRow(title: "V1: Message Channels", body: AutoSizeText("Manual, Slow, and Error Prone")),
              if (step > 1) TitleRow(title: "V2: Pigeon", body: AutoSizeText("Partly automated, still slow")),
              if (step > 2) TitleRow(title: "V3: Manual FFI", body: AutoSizeText("Manual, faster")),
              if (step > 3) ...[Divider(), TitleRow(title: "V4: Automatic FFI", body: AutoSizeText("Easy & Fast"))],
            ],
          );
        },
      ),
    );
  }
}
