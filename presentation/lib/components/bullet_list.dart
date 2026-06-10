import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ffi_presentation/components/default_text.dart';
import 'package:flutter_ffi_presentation/components/helpers.dart';

const alphabetLower = "abcdefghijklmnopqrstuvwxyz";

class ListItem {
  final String text;
  final List<ListItem> subItems;

  ListItem(this.text, {this.subItems = const []});

  @override
  bool operator ==(Object other) {
    return super == other && other is ListItem && text == other.text && listEquals(subItems, other.subItems);
  }

  @override
  int get hashCode => Object.hash(text, Object.hashAll(subItems));
}

class ListColumn extends StatelessWidget {
  const ListColumn(this.items, {super.key, this.depth = 0, this.numbered = false});

  final List<ListItem> items;
  final int depth;
  final bool numbered;

  static const double bulletSize = 20;

  static Widget _circleBullet(Color color, double size) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: SizedBox.square(dimension: size),
  );

  static Widget _emptyCircleBullet(Color color, double size) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: BoxBorder.all(color: color, width: 2),
    ),
    child: SizedBox.square(dimension: size),
  );

  static Widget _squareBullet(Color color, double size) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.rectangle),
    child: SizedBox.square(dimension: size),
  );

  static const _bullets = <Widget Function(Color color, double size)>[_circleBullet, _emptyCircleBullet, _squareBullet];

  @override
  Widget build(BuildContext context) {
    final color = context.theme.colorScheme.onSurface;
    final bullet = _bullets[depth % _bullets.length](color, switch (depth) {
      0 => 20.0,
      1 => 15.0,
      _ => 12.5,
    });

    final double leftPadding = switch (depth) {
      0 => 0,
      _ => 60,
    };

    final double betweenItemsSpacing = switch (depth) {
      0 => 30,
      _ => 15,
    };

    final double betweenItemAndChildSpacing = switch (depth) {
      0 => 12.5,
      _ => 10,
    };

    return DefaultTextFunc(
      fromTextTheme: (theme) => switch (depth) {
        0 => theme.displaySmall!,
        1 => theme.titleLarge!,
        _ => theme.titleMedium!,
      },
      child: Padding(
        padding: EdgeInsets.only(left: leftPadding),
        child: Column(
          spacing: betweenItemsSpacing,
          children: items.indexed.map((i) {
            final (index, item) = i;
            return Column(
              spacing: betweenItemAndChildSpacing,
              children: [
                Row(
                  crossAxisAlignment: .center,
                  children: [
                    numbered
                        ? AutoSizeText(
                            "${switch (depth) {
                              1 => alphabetLower[index % alphabetLower.length],
                              _ => index + 1,
                            }}.",
                          )
                        : bullet,
                    SizedBox(width: 20),
                    Expanded(child: AutoSizeText(item.text)),
                  ],
                ),
                if (item.subItems.isNotEmpty) ListColumn(item.subItems, depth: depth + 1, numbered: numbered),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
