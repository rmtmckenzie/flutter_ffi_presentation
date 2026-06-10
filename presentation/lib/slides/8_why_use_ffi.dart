import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/text_column.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

class WhyUseFfi extends SlideWidget {
  const WhyUseFfi({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/why-use-ffi",
          header: FlutterDeckHeaderConfiguration(title: "Why use FFI?"),
          steps: 5,
          speakerNotes: """
Images: 
 - opencv - image manipulation, computer vision
 - liteRT - run models locally
 - SQLIte - database
 - LibSodium - encryption
""",
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 10,
      children: [
        TextsColumn(
          texts: [
            "Need more performance than Dart is capable of *",
            "Need access to operating system functions",
            "More advanced threading, locking, etc",
            "Flutter's traditional native interop is SLOW and INCONVENIENT",
            "Libraries already exist in different languages",
          ],
        ),
        Expanded(
          child: FlutterDeckSlideStepsBuilder(
            builder: (context, step) {
              return Row(
                children: [
                  Expanded(
                    child: Visibility(visible: step > 1, child: Image.asset("assets/why/opencv.png", height: 100)),
                  ),
                  Expanded(
                    child: Visibility(visible: step > 2, child: Image.asset("assets/why/litert.webp", height: 100)),
                  ),
                  Expanded(
                    child: Visibility(visible: step > 3, child: Image.asset("assets/why/sqlite.png", height: 100)),
                  ),
                  Expanded(
                    child: Visibility(visible: step > 4, child: Image.asset("assets/why/libsodium.png", height: 100)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
