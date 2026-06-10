import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/bullet_list.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class IrlSlide extends SlideWidget {
  const IrlSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/irl",
          header: FlutterDeckHeaderConfiguration(title: "What I'd do differently IRL"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return ListColumn(
      [
        ListItem("use miniaudio everywhere (it supports android/ios"),
        ListItem( "do processing directly on thread that receives audio"),
        ListItem( "pass processed data back to dart"),
      ],
    );
  }
}
