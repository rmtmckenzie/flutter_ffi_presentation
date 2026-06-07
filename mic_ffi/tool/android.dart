import 'dart:io';
import 'package:jnigen/jnigen.dart';

void main() async {

  final config = Config(
    androidSdkConfig: AndroidSdkConfig(
      addGradleDeps: true,
      androidExample: 'example/',
    ),

    classes: [
      'android.media.AudioRecord',
      'android.media.AudioFormat',
      'android.media.MediaRecorder',
    ],

    outputConfig: OutputConfig(
      dartConfig: DartCodeOutputConfig(
        path: Uri.file('lib/src/internal/android_bindings.generated.dart'),
        structure: .singleFile,
      ),
    ),
  );

  try {
    await generateJniBindings(config);
  } catch (e) {
    stderr.writeln('❌ JNIGen generation failed: $e');
    exit(1);
  }
}