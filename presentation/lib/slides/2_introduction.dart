import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

class IntroSlide extends SlideWidget {
  const IntroSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: '/intro',
          // initial: true,
          header: FlutterDeckHeaderConfiguration(title: 'Introduction'),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return TitleRowFlex(
      titleFlex: 1,
      bodyFlex: 3,
      child: Column(
        spacing: 20,
        children: [
          TitleRow(title: "Who am I?", body: AutoSizeText("Morgan McKenzie")),
          TitleRow(
            title: "What do I do?",
            body: TitleRowBodyColumn(
              children: [
                AutoSizeText("Keepsta - Startup"),
                AutoSizeText("Smart Receipts, web based and in app"),
                AutoSizeText("Flutter"),
              ],
            ),
          ),
          TitleRow(
            title: "Flutter Experience",
            body: TitleRowBodyColumn(
              children: [
                AutoSizeText("Started way back in 2017"),
                AutoSizeText("Various apps - Rootd"),
                AutoSizeText("Stackoverflow"),
              ],
            ),
          ),
          TitleRow(
            title: "Packages",
            body: TitleRowBodyColumn(children: [AutoSizeText("Native Orientation"), AutoSizeText("QR Mobile Vision")]),
          ),
        ],
      ),
    );
  }
}
