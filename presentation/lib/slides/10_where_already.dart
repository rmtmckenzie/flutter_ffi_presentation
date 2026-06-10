import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

class WhereIsFfi extends SlideWidget {
  const WhereIsFfi({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/where-is-ffi",
          header: FlutterDeckHeaderConfiguration(title: "Where is FFI Already"),
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
          TitleRow(title: "SQFlite", body: AutoSizeText("Speeds up database operations")),
          TitleRow(title: "ZXing", body: AutoSizeText("Processing Images - Not ported to Dart (at least not well)")),
          TitleRow(title: "Box", body: AutoSizeText("Need FFI for performance")),
          TitleRow(title: "Win32", body: AutoSizeText("Call Win32 directly")),
          TitleRow(title: "pdfrx", body: AutoSizeText("Uses PDFium library")),
          TitleRow(title: "dbus", body: AutoSizeText("Need to access linux libraries")),

        ],
      ),
    );
  }
}
