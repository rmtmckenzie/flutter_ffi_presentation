import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffi_presentation/components/default_text.dart';

class TextSizedColumn extends StatelessWidget {
  final List<Widget> children;
  final TextStyleFromTextTheme fromTextTheme;

  const TextSizedColumn({super.key, required this.children, this.fromTextTheme = displaySmallFromTextTheme});

  @override
  Widget build(BuildContext context) {
    return DefaultTextFunc(
      fromTextTheme: fromTextTheme,
      child: Column(crossAxisAlignment: .start, spacing: 10, children: children),
    );
  }
}

class TextsColumn extends StatelessWidget {
  const TextsColumn({super.key, required this.texts, this.fromTextTheme = displaySmallFromTextTheme});

  final List<String> texts;
  final TextStyleFromTextTheme fromTextTheme;

  @override
  Widget build(BuildContext context) {
    return TextSizedColumn(fromTextTheme: fromTextTheme, children: texts.map((str) => AutoSizeText(str)).toList());
  }
}
