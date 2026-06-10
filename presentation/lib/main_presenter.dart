import 'package:flutter/material.dart';
import 'package:flutter_ffi_presentation/deck.dart';

void main() {
  runApp(const PresenterApp());
}

class PresenterApp extends StatelessWidget {
  const PresenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Deck(
      isPresenterView: true,
    );
  }
}
