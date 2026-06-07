import 'dart:io';

import 'package:ffigen/ffigen.dart';
import 'package:flutter/cupertino.dart';

void main() {

  final generator = FfiGenerator(
    output: Output(dartFile: Uri.parse('lib/src/internal/bindings.generated.dart'), style: NativeExternalBindings()),
    headers: Headers(entryPoints: [Uri.parse('src/miniaudio/miniaudio.h')]),
    functions: Functions.includeSet({'ma_device_config_init','ma_device_init', 'ma_device_start', 'ma_device_uninit', 'ma_device_stop'}),
    structs: Structs.includeSet({'ma_device_config', 'ma_device'}),
    enums: Enums.includeSet({'ma_format', 'ma_device_type'}),
    unnamedEnums: UnnamedEnums.includeSet({'ma_format_f32', 'ma_device_type_capture'}),
    typedefs: Typedefs.includeSet({'ma_device_data_proc', 'ma_device_data_procFunction'}),
  );

  try {
    generator.generate();
  } catch (e, s) {
    stderr.writeln('FFIGen generation failed: $e');
    debugPrintStack(stackTrace: s);
    exit(1);
  }
}
