// ignore_for_file: avoid_print

import 'dart:convert';

import "package:path/path.dart" show dirname, join;
import 'dart:io' show Platform, File;


/*
Unfortunately, miniaudio has enums that aren't compatible
with how FFI works. This is a quick fix that replaces the
enum definitions with ma_uint32 definitions while keeping
the enum names. This ensure that dart knows what size of
integer to pass across instead of potentially passing a
uint32 into a uint8 or vice-versa depending on how the
compiler decides to allocate size for the enum.
 */

final toFix = [
  'ma_aaudio_allowed_capture_policy',
  'ma_aaudio_content_type',
  'ma_aaudio_input_preset',
  'ma_aaudio_usage',
  'ma_attenuation_model',
  'ma_backend',
  'ma_channel_conversion_path',
  'ma_channel_mix_mode',
  'ma_data_converter_execution_path',
  'ma_device_notification_type',
  'ma_device_state',
  'ma_device_type',
  'ma_dither_mode',
  'ma_encoding_format',
  'ma_engine_node_type',
  'ma_format',
  'ma_handedness',
  'ma_ios_session_category',
  'ma_mono_expansion_mode',
  'ma_node_state',
  'ma_noise_type',
  'ma_opensl_recording_preset',
  'ma_opensl_stream_type',
  'ma_pan_mode',
  'ma_performance_profile',
  'ma_positioning',
  'ma_resample_algorithm',
  'ma_resource_manager_data_supply_type',
  'ma_result',
  'ma_seek_origin',
  'ma_share_mode',
  'ma_standard_channel_map',
  'ma_thread_priority',
  'ma_wasapi_usage',
  'ma_waveform_type',
];

Future<void> main() async {
  final dir = dirname(Platform.script.path);
  final file = File(join(dir, 'miniaudio', 'miniaudio.orig.h'))
      .openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter());

  final outFile = File(join(dir, 'miniaudio', 'miniaudio.h'))
    .openWrite();

  RegExp typeDef = RegExp(r'\s*typedef enum');
  RegExp enumName = RegExp(r'\s*} (ma_\w+);\s*');
  RegExp bracket = RegExp(r'\s*}');

  final enumLines = [];
  bool foundEnum = false;
  await for (final line in file) {
    if (foundEnum) {
      if (line.startsWith(bracket)) {
        final match = enumName.matchAsPrefix(line);
        final name = match?.group(1);
        if (name != null && toFix.contains(name)) {
          print("Found enum $name");
          outFile.writeln('typedef ma_uint32 $name;');
          outFile.writeln('enum');
          for(final l in enumLines) {
            outFile.writeln(l);
          }
          outFile.writeln("};");
        } else {
          // internal or unnamed so ignore
          outFile.writeln('typedef enum');
          for(final l in enumLines) {
            outFile.writeln(l);
          }
          outFile.writeln(line);
        }
        enumLines.clear();
        foundEnum = false;
      } else {
        enumLines.add(line);
      }
    } else if (typeDef.matchAsPrefix(line) != null) {
      foundEnum = true;
    } else {
      outFile.writeln(line);
    }
  }


}

