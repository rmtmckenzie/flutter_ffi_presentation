import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';
import 'package:flutter_ffi_presentation/components/title_row.dart';

const bindings = """
abstract class MonocypherBindings {
  void crypto_eddsa_key_pair(
    CryptoPointer secretKey,
    CryptoPointer publicKey,
    CryptoPointer seed,
  );

  void crypto_eddsa_sign(
    CryptoPointer signature,
    CryptoPointer secretKey,
    CryptoPointer message,
    int messageLength,
  );

  int crypto_eddsa_check(
    CryptoPointer signature,
    CryptoPointer publicKey,
    CryptoPointer message,
    int messageLength,
  );
}
""";

const pointer = """
class FfiCryptoPointer implements CryptoPointer {
  FfiCryptoPointer(this.pointer);

  final ffi.Pointer<ffi.Uint8> pointer;

  @override
  Uint8List asTypedList(int length) {
    return pointer.asTypedList(length);
  }

  @override
  void free() {
    malloc.free(pointer);
  }
}
""";

const impl = """
  @override
  void crypto_eddsa_sign(
    CryptoPointer signature,
    CryptoPointer secretKey,
    CryptoPointer message,
    int messageLength,
  ) {
    native_bindings.crypto_eddsa_sign(
      (signature as FfiCryptoPointer).pointer,
      (secretKey as FfiCryptoPointer).pointer,
      (message as FfiCryptoPointer).pointer,
      messageLength,
    );
  }
""";

class HowToUseDesktop extends SlideWidget {
  const HowToUseDesktop({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/how-to-use-desktop",
          steps: 3,
          header: FlutterDeckHeaderConfiguration(title: "How To: Monocypher - Code"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: FlutterDeckSlideStepsBuilder(builder: (context, step) {
        switch(step) {
          case 1:
            return FlutterDeckCodeHighlight(code: bindings);
          case 2:
            return FlutterDeckCodeHighlight(code: pointer);
          case 3:
            return FlutterDeckCodeHighlight(code: impl);
          default:
            return SizedBox();
        }

      }),
    );
  }
}
