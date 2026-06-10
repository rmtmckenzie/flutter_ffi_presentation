

import 'package:flutter/material.dart';
import 'package:flutter_ffi_presentation/components/helpers.dart';

typedef TextStyleFromTextTheme = TextStyle Function(TextTheme textTheme);
TextStyle displaySmallFromTextTheme(TextTheme textTheme) => textTheme.displaySmall!;

class DefaultTextFunc extends StatelessWidget {
  const DefaultTextFunc({super.key, required this.child, this.fromTextTheme = displaySmallFromTextTheme});

  final TextStyleFromTextTheme fromTextTheme;

  final Widget child;
  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return DefaultTextStyle(
      style: fromTextTheme(textTheme),
      child: child,
    );
  }
}
