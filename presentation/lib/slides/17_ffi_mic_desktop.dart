import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/bullet_list.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';


const enums = """
typedef enum
{
    ma_seek_origin_start,
    ma_seek_origin_current,
    ma_seek_origin_end  /* Not used by decoders. */
} ma_seek_origin;

//---------

typedef ma_uint32 ma_seek_origin;
enum
{
    ma_seek_origin_start,
    ma_seek_origin_current,
    ma_seek_origin_end  /* Not used by decoders. */
};
""";

const buildCode = """
  final generator = FfiGenerator(
    output: Output(dartFile: 
      Uri.parse('lib/src/internal/bindings.generated.dart'),
      style: NativeExternalBindings()),
    headers: Headers(entryPoints: [
      Uri.parse('src/miniaudio/miniaudio.h')]),
    functions: Functions.includeSet({
      'ma_device_config_init',
      'ma_device_init',
      'ma_device_start',
      'ma_device_uninit',
      'ma_device_stop'
    }),
    structs: Structs.includeSet({
      'ma_device_config', 
      'ma_device'
    }),
    enums: Enums.includeSet({
      'ma_format', 
      'ma_device_type'
    }),
    unnamedEnums: UnnamedEnums.includeSet({
      'ma_format_f32', 
      'ma_device_type_capture'
    }),
    typedefs: Typedefs.includeSet({
      'ma_device_data_proc', 
      'ma_device_data_procFunction'
    }),
  );
""";

class FfiMicSetup extends SlideWidget {
  const FfiMicSetup({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/ffi-mic-setup",
          initial: true,
          steps: 3,
          header: FlutterDeckHeaderConfiguration(title: "FFI Microphone - Desktop"),
          speakerNotes: """
Similar to monocypher.c
          """,
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListColumn([
            ListItem("Drop in library"),
            ListItem("Compile", subItems: [ListItem("Fix enums"), ListItem("Filter functions, structs, etc")]),
          ]),
        ),
        Expanded(
          child: Center(
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, step) {
                switch (step) {
                  case 1:
                    return Image.asset("assets/ffi_desktop/files.png");
                  case 2:
                    return FlutterDeckCodeHighlight(
                      code: enums,
                      language: 'dart',
                      fileName: "miniaudio.h",
                      textStyle: TextStyle(fontSize: 15),
                    );
                  case 3:
                    return FlutterDeckCodeHighlight(
                      code: buildCode,
                      language: 'dart',
                      fileName: "build.yaml",
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
