import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_ws_client/flutter_deck_ws_client.dart';
import 'package:flutter_ffi_presentation/components/background.dart';
import 'package:flutter_ffi_presentation/slides/10_where_already.dart';
import 'package:flutter_ffi_presentation/slides/11_how_to_use_ffi.dart';
import 'package:flutter_ffi_presentation/slides/12_how_to_use_compile.dart';
import 'package:flutter_ffi_presentation/slides/13_how_to_use_desktop.dart';
import 'package:flutter_ffi_presentation/slides/15_how_to_use_web.dart';
import 'package:flutter_ffi_presentation/slides/14_how_to_use_result.dart';
import 'package:flutter_ffi_presentation/slides/16_ffi_mic.dart';
import 'package:flutter_ffi_presentation/slides/17_ffi_mic_desktop.dart';
import 'package:flutter_ffi_presentation/slides/19_ffi_mic_android.dart';
import 'package:flutter_ffi_presentation/slides/20_ffi_mic_ios.dart';
import 'package:flutter_ffi_presentation/slides/1_title.dart';
import 'package:flutter_ffi_presentation/slides/21_ffi_mic_ios_marshaller.dart';
import 'package:flutter_ffi_presentation/slides/22_ffi_mic_web.dart';
import 'package:flutter_ffi_presentation/slides/23_issues.dart';
import 'package:flutter_ffi_presentation/slides/23_irl.dart';
import 'package:flutter_ffi_presentation/slides/24_questions.dart';
import 'package:flutter_ffi_presentation/slides/25_summary.dart';
import 'package:flutter_ffi_presentation/slides/2_introduction.dart';
import 'package:flutter_ffi_presentation/slides/3_outline.dart';
import 'package:flutter_ffi_presentation/slides/4_who.dart';
import 'package:flutter_ffi_presentation/slides/5_how_plugins_used_to_work.dart';
import 'package:flutter_ffi_presentation/slides/6_what_is_ffi.dart';
import 'package:flutter_ffi_presentation/slides/7_what_is_ffi_now.dart';
import 'package:flutter_ffi_presentation/slides/8_why_use_ffi.dart';
import 'package:flutter_ffi_presentation/slides/9_when_not_to_use.dart';
import 'package:google_fonts/google_fonts.dart';

class Deck extends StatelessWidget {
  const Deck({super.key, this.isPresenterView = false});

  final bool isPresenterView;

  @override
  Widget build(BuildContext context) {
    var darkTheme = ThemeData.dark();
    darkTheme = darkTheme.copyWith(textTheme: GoogleFonts.montserratTextTheme(darkTheme.textTheme));

    var lightTheme = ThemeData.light();
    lightTheme = lightTheme.copyWith(textTheme: GoogleFonts.montserratTextTheme(lightTheme.textTheme));

    var darkDeckTheme = FlutterDeckThemeData.fromTheme(darkTheme);
    darkDeckTheme = darkDeckTheme.copyWith(codeHighlightTheme: darkDeckTheme.codeHighlightTheme.copyWith(
      textStyle: GoogleFonts.googleSansCode(fontSize: 20),
      backgroundColor: Colors.black.withValues(alpha: 0.5),
    ));

    var lightDeckTheme = FlutterDeckThemeData.fromTheme(lightTheme);
    lightDeckTheme = lightDeckTheme.copyWith(codeHighlightTheme: lightDeckTheme.codeHighlightTheme.copyWith(
      textStyle: GoogleFonts.googleSansCode(fontSize: 20),
      backgroundColor: Colors.white.withValues(alpha: 0.5),
    ));

    return FlutterDeckApp(
      client: FlutterDeckWsClient(uri: Uri.parse('ws://localhost:8080')),
      // Use the WebSocket client
      isPresenterView: isPresenterView,
      configuration: FlutterDeckConfiguration(
        background: FlutterDeckBackgroundConfiguration(
          light: FlutterDeckBackground.custom(
            child: Background(
              color1: Color(0x00e1e1e1),
              color2: Color(0x00ebebeb),
              intensity: 10,
              speed: 0.3,
              child: SizedBox.expand(),
            ),
          ),
          dark: FlutterDeckBackground.custom(
            child: Background(color1: Color(0x00191919), color2: Color(0x00292929), child: SizedBox.expand()),
            // child: Background(color1: Colors.red, color2: Colors.blue, child: SizedBox.expand()),
          ),
        ),
        footer: FlutterDeckFooterConfiguration(showSlideNumbers: true),
        header: FlutterDeckHeaderConfiguration(showHeader: false),
        marker: FlutterDeckMarkerConfiguration(color: Colors.deepOrange),
        progressIndicator: FlutterDeckProgressIndicator.gradient(
          gradient: LinearGradient(colors: [Colors.red, Colors.blue], begin: .topLeft, end: .topRight),
          backgroundColor: Colors.black,
        ),
        showProgress: true,
        slideSize: FlutterDeckSlideSize.fromAspectRatio(aspectRatio: .ratio16x9(), resolution: .fromWidth(1440)),
        transition: FlutterDeckTransition.fade(),
      ),
      themeMode: ThemeMode.dark,
      darkTheme: darkDeckTheme,
      lightTheme: lightDeckTheme,
      speakerInfo: const FlutterDeckSpeakerInfo(
        name: "Morgan McKenzie",
        description: "CTO of Keepsta",
        socialHandle: "@rmtmckenzie",
        imagePath: "assets/headshot.jpg",
      ),
      slides: [
        TitleSlide(),
        IntroSlide(),
        OutlineSlide(),
        WhoSlide(),
        HowUsedToWorkSlide(),
        WhatIsFfi(),
        WhatIsFfiNow(),
        WhyUseFfi(),
        WhenNotToUse(),
        WhereIsFfi(),
        HowUseFfi(),
        HowToUseCompiling(),
        HowToUseDesktop(),
        HowToUseResult(),
        HowToUseWeb(),
        FfiMic(),
        FfiMicSetup(),
        FfiMicAndroid(),
        FFIMicIOS(),
        FFIMicIOSMarshaller(),
        FfiMicWeb(),
        IssuesSlide(),
        IrlSlide(),
        QuestionsSlide(),
        SummarySlide(),
      ],
      // colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
