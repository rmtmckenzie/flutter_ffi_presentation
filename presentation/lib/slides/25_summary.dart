import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class SummarySlide extends SlideWidget {
  const SummarySlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/summary",
          steps: 2,
          header: FlutterDeckHeaderConfiguration(title: "Summary"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ListColumn(numbered: true, [
            ListItem(
              "What you've seen:",
              subItems: [
                ListItem("Compiling C in-place"),
                ListItem("Using FFIGen to generate bindings"),
                ListItem("Using JNIGen for android"),
                ListItem("Using FFIGen for iOS"),
              ],
            ),
            ListItem(
              "Repos",
              subItems: [
                ListItem("https://github.com/rmtmckenzie/flutter_monocypher"),
                ListItem("https://github.com/rmtmckenzie/flutter_ffi_presentation"),
              ],
            ),
          ]),
        ),
        FlutterDeckSlideStepsBuilder(
          builder: (context, step) {
            return Expanded(
              flex: 1,
              child: Column(
                spacing: 10,
                children: [
                  AutoSizeText(step == 1 ? "Monocypher" : "FFI Presentation", style: TextStyle(fontSize: 25)),
                  PrettyQrView.data(
                    data: step == 1
                        ? "https://github.com/rmtmckenzie/flutter_monocypher"
                        : "https://github.com/rmtmckenzie/flutter_ffi_presentation",
                    decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
