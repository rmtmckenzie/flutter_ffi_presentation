import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffi_presentation/components/helpers.dart';

class TitleRowFlex extends InheritedWidget {
  const TitleRowFlex({super.key, required this.titleFlex, required this.bodyFlex, required super.child});

  final int titleFlex;
  final int bodyFlex;

  static TitleRowFlex of(BuildContext context) {
    final TitleRowFlex? result = context.dependOnInheritedWidgetOfExactType<TitleRowFlex>();
    assert(result != null, 'No TitleRowFlex found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(TitleRowFlex old) {
    return old.titleFlex != titleFlex || old.bodyFlex != bodyFlex;
  }
}

class TitleRow extends StatelessWidget {
  const TitleRow({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final titleRowFlex = TitleRowFlex.of(context);
    return Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: titleRowFlex.titleFlex,
          child: AutoSizeText(title, style: textTheme.headlineMedium),
        ),
        Expanded(
          flex: titleRowFlex.bodyFlex,
          child: DefaultTextStyle(
            style: textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w200),
            child: body,
          ),
        ),
      ],
    );
  }
}

class TitleRowBodyColumn extends StatelessWidget {
  final List<Widget> children;

  const TitleRowBodyColumn({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
