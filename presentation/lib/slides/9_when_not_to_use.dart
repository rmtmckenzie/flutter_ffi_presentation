import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/helpers.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/text_column.dart';

class WhenNotToUse extends SlideWidget {
  const WhenNotToUse({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/when-not-to-use",
          header: FlutterDeckHeaderConfiguration(title: "When NOT to use FFI"),
          steps: 3,
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    final colors = context.theme.colorScheme;

    return Stack(
      fit: .expand,
      children: [
        TextsColumn(
          texts: [
            "Existing Library Works",
            "Small Operations",
            "Performance not Critical",
            "Optimizations can be done in Dart",
          ],
        ),
        Positioned(
          right: 30,
          top: 0,
          child: FlutterDeckSlideStepsBuilder(
              builder: (context, step) {
                return Visibility(
                  visible: step > 1,
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(color: colors.onSecondary, borderRadius: .circular(30)),
                    child: TextsColumn(texts: ["Int32x4 (SIMD)", "@pragma('vm:prefer-inline)", "const", "caching/pooling"], fromTextTheme: (textTheme) => textTheme.titleLarge!,),
                  ),
                );
              }
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FlutterDeckSlideStepsBuilder(
            builder: (context, step) {
              return Visibility(
                visible: step > 2,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(color: colors.onTertiary, borderRadius: .circular(30)),
                    child: TextsColumn(texts: ["Debugging is a DIFFICULT", "Manual Memory Management", "Threading Pitfalls"]),
                  ),
                ),
              );
            }
          ),
        ),
      ],
    );
  }
}
