import 'package:flutter/material.dart';
import 'package:mic_ffi/mic_ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum RunState { initial, running, stopped }

class _MyAppState extends State<MyApp> {
  // String _platformVersion = 'Unknown';
  final _micFfiPlugin = MicFfi();
  RunState _runState = .initial;
  double? volume;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          children: [
            // make it take full width
            SizedBox(width: double.infinity),
            OutlinedButton(
              onPressed: () {
                switch(_runState) {
                  case .initial:
                  case .stopped:
                    _micFfiPlugin.startCapture();
                    setState(() {
                      _runState = .running;
                    });
                    break;
                  case.running:
                    _micFfiPlugin.stopCapture();
                    setState(() {
                      _runState = .stopped;
                    });
                    break;
                }
              },
              child: Text(switch (_runState) {
                .initial => "Start",
                .running => "Stop",
                .stopped => "Restart",
              }),
            ),
            Text('State: $_runState'),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  volume = _micFfiPlugin.volume;
                });
              },
              child: Text("Get Volume"),
            ),
            Text("Volume: ${volume ?? 'n/a'}"),
          ],
        ),
      ),
    );
  }
}
