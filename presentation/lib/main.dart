import 'package:flutter/material.dart';
import 'package:flutter_ffi_presentation/deck.dart';

void main() {
  runApp(const PresentationApp());
}

class PresentationApp extends StatelessWidget {
  const PresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Deck();
  }
}
