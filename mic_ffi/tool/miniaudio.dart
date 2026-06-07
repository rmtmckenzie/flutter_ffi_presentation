import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  print('🎬 Starting Programmatic FfiGenerator for Miniaudio...');

  final generator = FfiGenerator(
    // Replaces 'name' and 'description'
    // name: 'FlutterMonocypherBindings',
    // description: 'Bindings for `src/miniaudio/miniaudio.h`.\n\n'
    //     'Regenerate bindings with `dart run tool/miniaudio.dart`.',

    // Replaces 'output' - Takes an Output object directly
    output: Output(dartFile: Uri.parse('lib/src/internal/bindings.generated.dart'), style: NativeExternalBindings()),

    // Replaces 'headers' - Takes a Headers object directly
    headers: Headers(entryPoints: [Uri.parse('src/miniaudio/miniaudio.h')]),
    functions: Functions.includeSet({'ma_device_config_init','ma_device_init', 'ma_device_start', 'ma_device_uninit', 'ma_device_stop'}),
    structs: Structs.includeSet({'ma_device_config', 'ma_device'}),
    enums: Enums.includeSet({'ma_format', 'ma_device_type'}),
    unnamedEnums: UnnamedEnums.includeSet({'ma_format_f32', 'ma_device_type_capture'}),
    typedefs: Typedefs.includeSet({'ma_device_data_proc', 'ma_device_data_procFunction'}),
  );

  try {
    // Execute the generation directly
    generator.generate();
    print('✅ Successfully generated Miniaudio C bindings!');
  } catch (e) {
    stderr.writeln('❌ FFIGen generation failed: $e');
    exit(1);
  }
}
