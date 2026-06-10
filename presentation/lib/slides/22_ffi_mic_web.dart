import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

class FfiMicWeb extends SlideWidget {
  const FfiMicWeb({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/ffi-mic-web",
          header: FlutterDeckHeaderConfiguration(title: "CHANGE ME"),
        ),
      );

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
