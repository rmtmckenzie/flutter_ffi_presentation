// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:typed_data';

import 'package:mic_ffi/interface.dart';
import 'dart:async';
import 'dart:js_interop'; // Required for modern JS interop types
import 'dart:math' as math;
import 'package:web/web.dart' as web; // The official modern web interop package

MicFfi createMicEngine() {
  return WebMicEngine();
}

class WebMicEngine implements MicFfi {
  web.AudioContext? _audioContext;
  web.MediaStream? _mediaStream;
  web.MediaStreamAudioSourceNode? _sourceNode;
  web.AnalyserNode? _analyserNode;

  // Float32List is automatically mapped to JS Float32Array under the hood
  late Float32List _timeDomainBuffer;
  double _currentVolume = 0.0;
  Timer? _pollingTimer;

  @override
  Future<void> startCapture() async {
    if (_audioContext != null) return; // Already capturing

    // 1. Request microphone hardware permissions from the browser
    final mediaDevices = web.window.navigator.mediaDevices;

    // Construct the JS constraints object: { audio: true }
    final constraints = {'audio': true}.jsify() as web.MediaStreamConstraints;


    // Await the native browser promise resolution
    _mediaStream = await mediaDevices.getUserMedia(constraints).toDart;

    // 2. Initialize the Web Audio Context graph
    _audioContext = web.AudioContext();
    _sourceNode = _audioContext!.createMediaStreamSource(_mediaStream!);

    // 3. Create the AnalyserNode to handle the audio frequency spectrum
    _analyserNode = _audioContext!.createAnalyser();
    _analyserNode!.fftSize = 256; // Small window size for real-time volume tracking

    // Allocate a matching typed list to hold the incoming float samples
    _timeDomainBuffer = Float32List(_analyserNode!.frequencyBinCount);

    // 4. Connect the audio nodes together
    _sourceNode!.connect(_analyserNode!);

    // 5. Start a periodic timer to poll the audio stream (e.g., every 16ms for 60FPS updates)
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _calculateWebVolume();
    });
  }

  void _calculateWebVolume() {
    if (_analyserNode == null) return;

    // Grab the live waveform data from the browser's native audio buffer.
    // The jsify() layer handles passing our Dart Float32List directly to the JS engine.
    _analyserNode!.getFloatTimeDomainData(_timeDomainBuffer.toJS);

    // Perform your standard, lightning-fast RMS math loop right over the floats
    double sumOfSquares = 0.0;
    for (int i = 0; i < _timeDomainBuffer.length; i++) {
      // getByteTimeDomainData normalizes wave values around 128 (8-bit center)
      final double normalizedSample = (_timeDomainBuffer[i] - 128.0) / 128.0;
      sumOfSquares += normalizedSample * normalizedSample;
    }

    _currentVolume = math.sqrt(sumOfSquares / _timeDomainBuffer.length);
  }

  @override
  double get volume => _currentVolume;

  @override
  Future<void> stopCapture() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    // Stop all native hardware tracks to shut down the physical microphone recording light
    final tracks = _mediaStream?.getTracks().toDart ?? [];
    for (final track in tracks) {
      track.stop();
    }

    // Clean up and close down the browser audio graph infrastructure gracefully
    if (_audioContext != null) {
      await _audioContext!.close().toDart;
    }

    _sourceNode?.disconnect();
    _mediaStream = null;
    _audioContext = null;
    _analyserNode = null;
    _currentVolume = 0.0;
  }
}