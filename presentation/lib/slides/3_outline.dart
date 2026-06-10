import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

class OutlineSlide extends SlideWidget {
  const OutlineSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/outline",
          header: FlutterDeckHeaderConfiguration(title: "Outline"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return TitleRowFlex(
      titleFlex: 0,
      bodyFlex: 12,
      child: Column(
        spacing: 20,
        children: [
          ("1: ", "The 5 W's of FFI (Who, What, When, Where, Why)"),
          ("2: ", "The HOW: The new way to integrate a C library"),
          ("3: ", "Typing up a loose end: WEB"),
          ("4: ", "Audio Project - Desktop, Android, iOS, Web"),
          ("5: ", "Learnings"),
          ("6: ", "Summary"),
        ].map<Widget>((i) => TitleRow(title: i.$1.padRight(5, ' '), body: AutoSizeText(i.$2))).toList(),
      ),
    );
  }
}
