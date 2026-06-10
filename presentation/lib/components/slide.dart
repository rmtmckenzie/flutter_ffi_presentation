import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/header.dart';
import 'package:flutter_ffi_presentation/constants.dart';

abstract class SlideWidget extends FlutterDeckSlideWidget {
  const SlideWidget({
    super.key,
    super.configuration,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
  });

  final EdgeInsets headerPadding;
  final EdgeInsets bodyPadding;

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return FlutterDeckSlide.blank(
      headerBuilder: buildHeader,
      builder: (context) => Padding(padding: bodyPadding - slidePadding, child: buildBody(context)),
    );
  }

  Widget buildHeader(BuildContext context) {
    return SlideHeader(padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20));
  }

  Widget buildBody(BuildContext context);
}
