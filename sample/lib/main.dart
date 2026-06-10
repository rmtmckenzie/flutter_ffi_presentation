import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mic_ffi/mic_ffi.dart';
import 'package:audio_process/audio_process.dart';
import 'package:permission_plus/permission_plus.dart';

import 'visualizer_data.dart';
import 'oscilloscope_painter.dart';
import 'spectrum_painter.dart';
import 'volume_painter.dart';
import 'pitch_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFI Audio Telemetry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFCC),      // Neon Green/Cyan for Waveform
          secondary: Color(0xFF7C4DFF),    // Neon Purple for Spectrum low
          tertiary: Color(0xFFFF4081),     // Neon Pink for Spectrum high/Volume
          surface: Color(0xFF161626),      // Glassmorphic Card Surface
          onSurface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161626),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final MicFfi _micFfi = MicFfi();
  final AudioPipeline _audioPipeline = AudioPipeline();

  StreamSubscription<Float32List>? _micSubscription;
  StreamSubscription<AudioTelemetry>? _telemetrySubscription;

  bool _isCapturing = false;
  bool _isPermissionDenied = false;

  final ValueNotifier<VisualizerData> _visualizerNotifier = ValueNotifier<VisualizerData>(VisualizerData.empty());
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Pulse animation controller for the floating mic button glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _stopCapture();
    _pulseController.dispose();
    _visualizerNotifier.dispose();
    super.dispose();
  }

  Future<void> _toggleCapture() async {
    if (_isCapturing) {
      await _stopCapture();
    } else {
      await _startCapture();
    }
  }

  Future<void> _startCapture() async {
    // Check and request microphone permissions using permission_handler
    final status = await PermissionPlus.requestPermission(.microphone);
    if (!mounted) return;

    if (status == .granted) {
      setState(() {
        _isPermissionDenied = false;
      });

      try {
        // Initialize the isolation audio pipeline at ~30 FPS ticks (33 milliseconds update interval)
        await _audioPipeline.initialize(updateInterval: const Duration(milliseconds: 33), noiseGateDb: 35.0);
        if (!mounted) return;

        // Pipe the mic stream directly into the isolation audio pipeline
        _micSubscription = _micFfi.stream().listen((Float32List buffer) {
          _audioPipeline.feedRawBuffer(buffer);
        });

        // Feed calculated telemetry to our UI notifier
        _telemetrySubscription = _audioPipeline.telemetryStream.listen((AudioTelemetry telemetry) {
          _visualizerNotifier.value = _visualizerNotifier.value.copyWithUpdatedTelemetry(telemetry, 100);
        });

        // Start hardware FFI mic capture
        await _micFfi.startCapture();

        _pulseController.repeat(reverse: true);
        setState(() {
          _isCapturing = true;
        });
      } catch (e) {
        debugPrint('Failed to start audio pipeline/capture: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Failed to start capture: $e'),
          ),
        );
        await _stopCapture();
      }
    } else {
      setState(() {
        _isPermissionDenied = true;
        _isCapturing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Microphone permission is required to analyze audio telemetry.'),
        ),
      );
    }
  }

  Future<void> _stopCapture() async {
    try {
      await _micFfi.stopCapture();
    } catch (e) {
      debugPrint('Error stopping mic capture: $e');
    }

    await _micSubscription?.cancel();
    _micSubscription = null;

    await _telemetrySubscription?.cancel();
    _telemetrySubscription = null;

    _audioPipeline.dispose();

    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isCapturing = false;
    });

    // Reset visualizer data to silent state
    _visualizerNotifier.value = VisualizerData.empty();
  }

  String _hzToNote(double hz) {
    if (hz <= 20.0 || hz.isNaN || hz.isInfinite) return 'Silence';
    // Standard MIDI scale pitch conversion: MIDI = 12 * log2(hz / 440) + 69
    final double midi = 12 * (math.log(hz / 440.0) / math.log(2)) + 69;
    final int midiRound = midi.round();
    if (midiRound < 0 || midiRound > 127) return 'Out of Range';

    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final String note = notes[midiRound % 12];
    final int octave = (midiRound / 12).floor() - 1;

    final double cents = (midi - midiRound) * 100;
    final String centsSign = cents >= 0 ? '+' : '';
    return '$note$octave ($centsSign${cents.toStringAsFixed(0)}¢)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Glassmorphic styled Header Info Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AUDIO TELEMETRY',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCapturing ? theme.colorScheme.primary : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCapturing ? 'STREAMING ACTIVE' : 'STREAMING IDLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isPermissionDenied)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                      ),
                      onPressed: PermissionPlus.openSettings,
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Grant Access', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),

            // Main Dashboard Grid Layout
            Expanded(
              child: GridView.count(
                crossAxisCount: isDesktop ? 2 : 1,
                childAspectRatio: isDesktop ? 1.4 : 1.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100), // bottom margin for float bar
                children: [
                  // 1. Oscilloscope Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(
                            title: 'TIME DOMAIN OSCILLOSCOPE',
                            icon: Icons.waves,
                            iconColor: theme.colorScheme.primary,
                          ),
                          Expanded(
                            child: ClipRect(
                              child: CustomPaint(
                                painter: OscilloscopePainter(
                                  dataNotifier: _visualizerNotifier,
                                  waveColor: theme.colorScheme.primary,
                                  gridColor: Colors.white.withValues(alpha: 0.04),
                                ),
                                child: Container(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Frequency Spectrum Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(
                            title: 'LOGARITHMIC FREQUENCY SPECTRUM (FFT)',
                            icon: Icons.equalizer,
                            iconColor: theme.colorScheme.secondary,
                          ),
                          Expanded(
                            child: ClipRect(
                              child: CustomPaint(
                                painter: SpectrumPainter(
                                  dataNotifier: _visualizerNotifier,
                                  startColor: theme.colorScheme.secondary,
                                  endColor: theme.colorScheme.tertiary,
                                  gridColor: Colors.white.withValues(alpha: 0.04),
                                ),
                                child: Container(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Loudness volume radial gauge Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(
                            title: 'LOUDNESS LEVEL (RMS)',
                            icon: Icons.volume_up,
                            iconColor: theme.colorScheme.tertiary,
                          ),
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                width: 140,
                                height: 140,
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      size: const Size(140, 140),
                                      painter: VolumePainter(
                                        dataNotifier: _visualizerNotifier,
                                        trackColor: Colors.white.withValues(alpha: 0.04),
                                        volumeColor: theme.colorScheme.tertiary,
                                      ),
                                    ),
                                    Center(
                                      child: ValueListenableBuilder<VisualizerData>(
                                        valueListenable: _visualizerNotifier,
                                        builder: (context, data, _) {
                                           final double vol = data.telemetry?.volume ?? 0.0;
                                           final double db = vol > 0.0000001
                                               ? (90.0 + 20.0 * (math.log(vol) / math.ln10)).clamp(0.0, 120.0)
                                               : 0.0;
                                           final String dbText = '${db.toStringAsFixed(1)} dB';

                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                dbText,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'RMS: ${vol.toStringAsFixed(3)}',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white.withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Pitch Tracker Timeline Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCardHeader(
                                title: 'PITCH TRACKER',
                                icon: Icons.music_note,
                                iconColor: theme.colorScheme.primary,
                              ),
                              ValueListenableBuilder<VisualizerData>(
                                valueListenable: _visualizerNotifier,
                                builder: (context, data, _) {
                                  final double currentHz = data.pitchHistory.last;
                                  return Text(
                                    currentHz > 20.0
                                        ? '${currentHz.toStringAsFixed(1)} Hz — ${_hzToNote(currentHz)}'
                                        : 'Silence',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: currentHz > 20.0
                                          ? theme.colorScheme.primary
                                          : Colors.white.withValues(alpha: 0.4),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Expanded(
                            child: ClipRect(
                              child: CustomPaint(
                                painter: PitchPainter(
                                  dataNotifier: _visualizerNotifier,
                                  lineColor: theme.colorScheme.primary,
                                  gridColor: Colors.white.withValues(alpha: 0.04),
                                  textColor: Colors.white,
                                ),
                                child: Container(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Glassmorphic Floating Bottom Navigation Control Bar
      bottomNavigationBar: Container(
        height: 84,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFF10101C).withValues(alpha: 0.85),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCapturing ? 'ANALYZING LIVE AUDIO' : 'READY TO RECORD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isCapturing ? theme.colorScheme.primary : Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isCapturing ? 'Press Red button to stop capture' : 'Press Mic button to begin telemetry',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulse = _pulseController.value;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isCapturing)
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.35 * (1.0 - pulse)),
                              blurRadius: 8.0 + (14.0 * pulse),
                              spreadRadius: 1.0 + (6.0 * pulse),
                            )
                          else
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8.0,
                              spreadRadius: 1.0,
                            ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Material(
                    type: MaterialType.circle,
                    color: _isCapturing ? Colors.redAccent : theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _toggleCapture,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isCapturing ? Colors.red : theme.colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _isCapturing ? Icons.stop : Icons.mic,
                            color: _isCapturing ? Colors.white : theme.colorScheme.primary,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
