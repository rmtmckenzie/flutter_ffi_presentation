import 'dart:developer';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';


class SlideHeader extends StatelessWidget {
  const SlideHeader({super.key, required this.padding});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterDeckHeaderTheme.of(context);
    final configuration = context.flutterDeck.configuration;

    return Container(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: padding,
        child: AutoSizeText(
          configuration.header.title,
          style: theme.textStyle?.copyWith(color: theme.color),
          maxFontSize: theme.textStyle?.fontSize ?? double.infinity,
        ),
      ),
    );
  }
}
