import 'package:flutter/material.dart';
import 'package:audio_process/audio_process.dart';

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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: AudioTelemetryView(),
      ),
    );
  }
}
