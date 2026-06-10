import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/constants.dart';

class TitleSlide extends FlutterDeckSlideWidget {
  const TitleSlide({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: '/title-slide',
          title: 'FFI in Flutter',

          footer: FlutterDeckFooterConfiguration(showFooter: false),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const subtitle = 'Get low, low, low, low, low, low, low (in the stack)';
    const content = "And JNI for Java/Kotlin\nand Objc-C\nand web.";

    return FlutterDeckSlide.template(
      contentBuilder: (context) {
        final speakerInfo = context.flutterDeck.speakerInfo;
        final theme = FlutterDeckTitleSlideTheme.of(context);
        final confTitle = context.flutterDeck.configuration.title;
        return Padding(
          padding: slidePadding * 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: AutoSizeText(confTitle ?? "", style: theme.titleTextStyle)),
              const SizedBox(height: 8),
              Flexible(child: AutoSizeText(subtitle, style: theme.subtitleTextStyle)),
              const SizedBox(height: 64),
              Row(
                children: [
                  Expanded(child: AutoSizeText(content, style: theme.subtitleTextStyle?.copyWith(fontSize: 24))),
                  if (speakerInfo != null) Expanded(child: FlutterDeckSpeakerInfoWidget(speakerInfo: speakerInfo)),
                ],
              ),
            ],
          ),
        );
      },
    );
    // return FlutterDeckSlide.title(
    //   // backgroundBuilder: (context) {
    //   //   return ColoredBox(color: Colors.transparent);
    //   // },
    //   title: 'FFI in Flutter',
    //   subtitle: 'Get low, low, low, low, low, low, low (in the stack)',
    // );
  }
}
