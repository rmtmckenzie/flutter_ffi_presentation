import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

const tool = """
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
        path: Uri.file(
          'lib/src/internal/android_bindings.generated.dart'
        ),
        structure: .singleFile,
      ),
    ),
  );

  try {
    await generateJniBindings(config);
  } catch (e) {
    stderr.writeln('JNIGen generation failed: \$e');
    exit(1);
  }
}
""";

const isolate = """
  @override
  Future<void> startCapture() async {
    if (_workerIsolate != null) return; // Already running
    if (_spawnFuture != null) {
      await _spawnFuture;
      return;
    }
    _receivePort = ReceivePort();

    _portSubscription = _receivePort!.listen((dynamic message) {
      if (message is SendPort) {
        _isolateCommandPort = message;
      } else if (message is Float32List) {
        _stream.add(message);
      }
    });

    final spawnCompleter = Completer();
    _spawnFuture = spawnCompleter.future;
    // Spawn using the static wrapper of custom worker
    _workerIsolate = await Isolate.spawn(AndroidMicWorker.spawnEntry, _receivePort!.sendPort);
    spawnCompleter.complete();
    _spawnFuture = null;
  }
""";

const record = r"""
  void _initAndRun() {
    // port setup left out
    
    const sampleRate = 44100;
    const audioFormat = AudioFormat.ENCODING_PCM_FLOAT;
    const channelConfig = AudioFormat.CHANNEL_IN_MONO;

    _bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat);
    _jniBuffer = JByteBuffer.allocateDirect(_bufferSize);

    final Uint8List rawBytesView = _jniBuffer.asUint8List();
    _pcmSamplesView = Float32List.view(rawBytesView.buffer);

    _audioRecord = AudioRecord(
      MediaRecorder$AudioSource.MIC, 
      sampleRate, 
      channelConfig, 
      audioFormat, 
      _bufferSize
    );

    _audioRecord.startRecording();
    _loop();
  }

  void _loop() async {
    while (_isRunning) {
      _audioRecord.read$3(_jniBuffer, _bufferSize);

      // copy to dart memory
      final copy = Float32List.fromList(_pcmSamplesView);
      _uiSendPort.send(copy.asUnmodifiableView());

      // Microscopic breath to allow the commandPort listener to check for "STOP"
      final nextFramePort = ReceivePort();
      Isolate.current.ping(nextFramePort.sendPort);
      await nextFramePort.first;
    }

    _cleanup();
  }
""";

class FfiMicAndroid extends SlideWidget {
  const FfiMicAndroid({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/ffi-mic-android",
          steps: 4,
          header: FlutterDeckHeaderConfiguration(title: "FFI Microphone - Android"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ListColumn([
            ListItem(
              "tool/android.dart",
              subItems: [
                ListItem("use JniGen"),
                ListItem(
                  "generate bindings",
                  subItems: [
                    ListItem("android.media.AudioRecord"),
                    ListItem("android.media.AudioFormat"),
                    ListItem("android.media.MediaRecorder"),
                  ],
                ),
              ],
            ),
            ListItem("new isolate", subItems: [ListItem("Call APIs Directly!"), ListItem("Simple!")]),
          ]),
        ),
        Expanded(
          flex: 10,
          child: Center(
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, step) {
                switch (step) {
                  case 2:
                    return FlutterDeckCodeHighlight(
                      code: tool,
                      language: 'dart',
                      fileName: "jnigen.dart",
                      textStyle: TextStyle(fontSize: 18),
                    );
                  case 3:
                    return FlutterDeckCodeHighlight(
                      code: isolate,
                      language: 'dart',
                      fileName: "isolate.dart",
                      textStyle: TextStyle(fontSize: 15),
                    );
                  case 4:
                    return FlutterDeckCodeHighlight(
                      code: record,
                      language: 'dart',
                      fileName: "record.dart",
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
