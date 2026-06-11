import 'dart:async';
import 'dart:typed_data';

import 'package:audio_process/src/audio_pipeline.dart';
import 'package:audio_process/src/audio_telemetry.dart';
import 'package:audio_process/src/widgets/oscilloscope_widget.dart';
import 'package:audio_process/src/widgets/pitch_tracker_widget.dart';
import 'package:audio_process/src/widgets/spectrum_widget.dart';
import 'package:audio_process/src/widgets/visualizer_data.dart';
import 'package:audio_process/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';
import 'package:mic_ffi/mic_ffi.dart';
import 'package:permission_plus/permission_plus.dart';

enum AudioTelemetryLayout {
  responsive,
  grid2x2,
  grid4x1,
  grid1x4,
}

class AudioTelemetryView extends StatefulWidget {
  final AudioTelemetryLayout layout;

  const AudioTelemetryView({
    super.key,
    this.layout = AudioTelemetryLayout.responsive,
  });

  @override
  State<AudioTelemetryView> createState() => _AudioTelemetryViewState();
}

class _AudioTelemetryViewState extends State<AudioTelemetryView> with SingleTickerProviderStateMixin {
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
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
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
          SnackBar(backgroundColor: Theme.of(context).colorScheme.error, content: Text('Failed to start capture: $e')),
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
    //TODO: clean up the disposal code
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

    if (mounted) {
      setState(() {
        _isCapturing = false;
      });
    }

    // Reset visualizer data to silent state
    _visualizerNotifier.value = VisualizerData.empty();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Column(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double height = constraints.maxHeight;

              final int columns;
              final int rows;

              switch (widget.layout) {
                case AudioTelemetryLayout.responsive:
                  if (isDesktop) {
                    columns = 2;
                    rows = 2;
                  } else {
                    columns = 1;
                    rows = 4;
                  }
                  break;
                case AudioTelemetryLayout.grid2x2:
                  columns = 2;
                  rows = 2;
                  break;
                case AudioTelemetryLayout.grid4x1:
                  columns = 4;
                  rows = 1;
                  break;
                case AudioTelemetryLayout.grid1x4:
                  columns = 1;
                  rows = 4;
                  break;
              }

              const double crossAxisSpacing = 16;
              const double mainAxisSpacing = 16;
              const double paddingHorizontal = 16;

              final double availableWidth = width - (paddingHorizontal * 2);
              final double itemWidth = (availableWidth - (crossAxisSpacing * (columns - 1))) / columns;
              final double itemHeight = (height - (mainAxisSpacing * (rows - 1))) / rows;

              final double childAspectRatio;
              if (itemWidth > 0 && itemHeight > 0) {
                childAspectRatio = itemWidth / itemHeight;
              } else {
                childAspectRatio = 1.0;
              }

              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OscilloscopeWidget(dataNotifier: _visualizerNotifier),
                  SpectrumWidget(dataNotifier: _visualizerNotifier),
                  VolumeWidget(dataNotifier: _visualizerNotifier),
                  PitchTrackerWidget(dataNotifier: _visualizerNotifier),
                ],
              );
            },
          ),
        ),

        // Glassmorphic Floating Bottom Navigation Control Bar
        Container(
          height: 84,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF10101C).withValues(alpha: 0.85),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5)),
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
                        style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.5)),
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
      ],
    );
  }
}
