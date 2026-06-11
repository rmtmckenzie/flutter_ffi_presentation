import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class QuestionsSlide extends SlideWidget {
  const QuestionsSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/questions",
          header: FlutterDeckHeaderConfiguration(title: "Future Questions"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return ListColumn(numbered: false, [
      ListItem(
        "SwiftGen",
        subItems: [
          ListItem("Wanted to include"),
          ListItem("Many caveats", subItems: [ListItem("@objc"), ListItem("intermediate steps")]),
        ],
      ),
      ListItem(
        "Platform View + FFI",
        subItems: [ListItem("not well defined"), ListItem("regular plugin likely needed")],
      ),
    ]);
  }
}
