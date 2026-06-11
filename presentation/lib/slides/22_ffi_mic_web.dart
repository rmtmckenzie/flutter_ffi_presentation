import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/list_column.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

const one = """
  web.AudioContext? _audioContext;
  web.MediaStream? _mediaStream;
  web.MediaStreamAudioSourceNode? _sourceNode;
  web.AnalyserNode? _analyserNode;

  // Float32List is automatically mapped to JS Float32Array
  late Float32List _timeDomainBuffer;
  final StreamController<Float32List> _streamController 
    = StreamController.broadcast();
  Timer? _pollingTimer;
""";

const two = """
  final mediaDevices = web.window.navigator.mediaDevices;

  final constraints = {'audio': true}.jsify() as web.MediaStreamConstraints;

  _mediaStream = await mediaDevices.getUserMedia(constraints).toDart;

  _audioContext = web.AudioContext();
  _sourceNode = _audioContext!.createMediaStreamSource(_mediaStream!);

  _analyserNode = _audioContext!.createAnalyser();
  _analyserNode!.fftSize = 256; 

  _timeDomainBuffer = Float32List(_analyserNode!.frequencyBinCount);

  _sourceNode!.connect(_analyserNode!);

  _pollingTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
    _pollAudio();
  });
""";

const three = """
  void _pollAudio() {
    if (_analyserNode == null) return;

    // Grab the live waveform data from the browser's native audio buffer.
     _analyserNode!.getFloatTimeDomainData(_timeDomainBuffer.toJS);

    _streamController.add(Float32List.fromList(_timeDomainBuffer));
  }
""";

class FfiMicWeb extends SlideWidget {
  const FfiMicWeb({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/ffi-mic-web",
          steps: 3,
          header: FlutterDeckHeaderConfiguration(title: "FFI Microphone - Web"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: ListColumn([
            ListItem("No Special build needed!"),
            ListItem("Use Js interoperability", subItems: [ListItem("js_interop"), ListItem("package:web")]),
            ListItem(
              "WebAudio APIs",
              subItems: [ListItem("AudioContext"), ListItem("MediaStream"), ListItem("AnalyserNode")],
            ),
          ]),
        ),
        Expanded(
          flex: 10,
          child: Center(
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, step) {
                switch (step) {
                  case 1:
                    return FlutterDeckCodeHighlight(code: one, textStyle: TextStyle(fontSize: 20));
                  case 2:
                    return FlutterDeckCodeHighlight(code: two, textStyle: TextStyle(fontSize: 15));
                  case 3:
                    return FlutterDeckCodeHighlight(code: three, textStyle: TextStyle(fontSize: 15));
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
