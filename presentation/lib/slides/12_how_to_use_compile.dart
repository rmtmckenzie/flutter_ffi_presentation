import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

const ffigenCode = """
name: FlutterMonocypherBindings
output: 'lib/src/internal/bindings.generated.dart'
headers:
  entry-points:
    - 'src/monocypher/monocypher.h'
  include-directives:
    - 'src/monocypher/monocypher.h'
ffi-native:
comments:
  style: any
  length: full
""";

const toolCode = """
import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final generator = FfiGenerator(
    output: Output(dartFile:
      Uri.parse('lib/src/internal/bindings.generated.dart'),
        style: NativeExternalBindings(),
        commentType: CommentType(.any, .full),
    ),
    headers: Headers(entryPoints: [
      Uri.parse('src/monocypher/monocypher.h')
    ]),
    functions: Functions.includeAll,
    structs: Structs(include: (name) {
      return !name.originalName.startsWith("_");
    }),
    globals: Globals.includeAll,
    macros: Macros.includeSet({
      "CRYPTO_ARGON2_D", "CRYPTO_ARGON2_I", "CRYPTO_ARGON2_ID"
    }),
  );

  try {
    generator.generate();
  } catch (e) {
    stderr.writeln('FFIGen generation failed: \$e');
    exit(1);
  }
}
""";

const buildCode = """
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:logging/logging.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final cBuilder = CBuilder.library(
      name: packageName,
      assetName: 'src/internal/bindings.generated.dart',
      sources: ['src/monocypher/monocypher.c'],
    );
    await cBuilder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = .ALL
        ..onRecord.listen((record) => print(record.message)),
    );
  });
}
""";

class HowToUseCompiling extends SlideWidget {
  const HowToUseCompiling({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/how-to-use-compile",
          steps: 4,
          header: FlutterDeckHeaderConfiguration(title: "How To: Monocypher - Compiling"),
          preloadImages: {"assets/how_to_monocypher/source.png"},
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListColumn(numbered: true, [
            ListItem("Drop source files in src/"),
            ListItem("Set up FFIGEN", subItems: [ListItem("ffigen.yaml, or"), ListItem("tool/*.dart")]),
            ListItem("Set up hook/build.dart"),
          ]),
        ),
        Expanded(
          child: Center(
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, step) {
                switch (step) {
                  case 1:
                    return Image.asset("assets/how_to_monocypher/source.png");
                  case 2:
                    return FlutterDeckCodeHighlight(code: ffigenCode, language: 'yaml', fileName: "ffigen.yaml");
                  case 3:
                    return FlutterDeckCodeHighlight(
                      code: toolCode,
                      language: 'dart',
                      fileName: "ffi.dart",
                      textStyle: TextStyle(fontSize: 15),
                    );
                  case 4:
                    return FlutterDeckCodeHighlight(
                      code: buildCode,
                      language: 'dart',
                      fileName: "build.dart",
                      textStyle: TextStyle(fontSize: 15),
                    );
                  default:
                    return SizedBox();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
