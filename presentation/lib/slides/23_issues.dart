import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/bullet_list.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

class IssuesSlide extends SlideWidget {
  const IssuesSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/issues-1",
          header: FlutterDeckHeaderConfiguration(title: "Issues I ran into."),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return ListColumn([
      ListItem(
         "Threading on IOS",
        subItems: [
          ListItem( "Need to pin isolate to thread"),
          ListItem(
            "Receive callbacks in particular thread & isolate",
            subItems: [ListItem( "No need for marshalling, could do processing in code")],
          ),
        ],
      ),
      ListItem(
         "Still having multiple copies of audio",
        subItems: [
          ListItem( "iOS Background Thread -> main, main -> processing"),
          ListItem( "android background thread -> processing"),
        ],
      ),
      ListItem( "Compilation", subItems: [
        ListItem( "ObjC usage is not well documented")
      ]),
    ]);
  }
}
