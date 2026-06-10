import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_ffi_presentation/components/slide.dart';

const allocation = """
#include "monocypher/monocypher.c"

#ifndef __wasm__
// Mock declarations for IDE static analyzer / code completion when running in native host mode
#define __builtin_wasm_memory_size(x) ((unsigned int)0)
#define __builtin_wasm_memory_grow(x, y) ((unsigned int)-1)
#endif

typedef struct Block {
    unsigned int size;
    int free;
    struct Block* next;
} Block;

#define BLOCK_SIZE sizeof(Block)

extern unsigned char __heap_base;
Block* freeList = 0;
unsigned int heap_top = 0;

void* wasm_malloc(unsigned int size) {
    if (heap_top == 0) {
        heap_top = (unsigned int)&__heap_base;
    }
    
    // Align size to 8 bytes for memory safety and alignment
    size = (size + 7) & ~7;
    
    // First fit search in existing blocks
    Block* curr = freeList;
    while (curr) {
        if (curr->free && curr->size >= size) {
            curr->free = 0;
            return (void*)(curr + 1);
        }
        curr = curr->next;
    }
    
    // Allocate a new block at heap_top
    unsigned int needed = BLOCK_SIZE + size;
    unsigned int current_memory_size = __builtin_wasm_memory_size(0) * 65536;
    if (heap_top + needed > current_memory_size) {
        unsigned int needed_bytes = heap_top + needed - current_memory_size;
        unsigned int needed_pages = (needed_bytes + 65535) / 65536;
        if (__builtin_wasm_memory_grow(0, needed_pages) == -1) {
            return 0; // Out of memory
        }
    }
    
    Block* block = (Block*)heap_top;
    block->size = size;
    block->free = 0;
    block->next = freeList;
    freeList = block;
    
    heap_top += needed;
    return (void*)(block + 1);
}

void wasm_free(void* ptr) {
    if (!ptr) return;
    Block* block = (Block*)ptr - 1;
    block->free = 1;
}
""";

const buildWasm = """
import 'dart:io';
import 'package:logging/logging.dart';

Future<void> buildWasm(String path) async {
  final parentDir = File(path).parent;
  if (!await parentDir.exists()) {
    await parentDir.create(recursive: true);
  }

  final result = await Process.run('clang', [
    '--target=wasm32',
    '-O3',
    '-nostdlib',
    '-Wl,--no-entry',
    '-Wl,--export-all',
    '-o',
    path,
    'src/monocypher_wasm.c',
  ]);

  if (result.exitCode != 0) {
    throw('WASM compilation failed: \${result.stderr}');
  } else {
    Logger.root.log(.INFO,'Successfully compiled WebAssembly to \$path');
  }
}


// Since linking non-code (as far as FFI is concerned) data
// is not supported as of yet, we're going to hack it
// in here. This can be run from the command line with
//
// > dart hook/build_wasm.dart
//
// This must be done before building for web.
void main(List<String> args) async {
  // Compile WebAssembly module for Web if clang is available
  try {
    print('Building WebAssembly monocypher.wasm...');
    await buildWasm('assets/monocypher.wasm');
  } catch (e) {
    print('Could not compile WebAssembly asset: \$e');
  }
}
""";

const glue = """
extension type MonocypherExports._(JSObject _) implements JSObject {
  external JSFunction get wasm_malloc;
  external JSFunction get wasm_free;
  external JSFunction get crypto_eddsa_key_pair;
  external JSFunction get crypto_eddsa_sign;
  external JSFunction get crypto_eddsa_check;
  external JSMemory get memory;
}

class WebCryptoPointer implements CryptoPointer {
  WebCryptoPointer(this.address, this.buffer, this.onFree);

  final int address;
  final Uint8List buffer;
  final void Function(int address) onFree;

  @override
  Uint8List asTypedList(int length) {
    return buffer.buffer.asUint8List(address, length);
  }

  @override
  void free() {
    onFree(address);
  }
}
""";

const load = """
Future<void> initWeb() async {
  if (_exportsInstance != null) return; // Already initialized

  final url = 'assets/packages/flutter_monocypher/assets/monocypher.wasm';
  try {
    final responseObj = await jsFetch(url.toJS).toDart;
    final response = FetchResponse._(responseObj);
    final arrayBuffer = await response.arrayBuffer().toDart;
    final jsBytes = JSUint8Array(arrayBuffer);

    final importObject = JSObject();
    final result = await WebAssembly.instantiate(jsBytes, importObject).toDart;
    _exportsInstance = result.instance.exports;
  } catch (e) {
    throw Exception(
      'Failed to load and initialize Monocypher WebAssembly from "\$url". '
      'Make sure that "assets/monocypher.wasm" is declared under assets '
      'in your pubspec.yaml and serves correctly. '
      'Error: \$e'
    );
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
    exports.crypto_eddsa_sign.callAsFunction(
      null,
      (signature as WebCryptoPointer).address.toJS,
      (secretKey as WebCryptoPointer).address.toJS,
      (message as WebCryptoPointer).address.toJS,
      messageLength.toJS,
    );
  }
""";

class HowToUseWeb extends SlideWidget {
  const HowToUseWeb({super.key})
    : super(
        configuration: const FlutterDeckSlideConfiguration(
          route: "/how-to-use-web",
          steps: 4,
          header: FlutterDeckHeaderConfiguration(title: "How to: Monocypher - Web"),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: FlutterDeckSlideStepsBuilder(
        builder: (context, step) {
          switch (step) {
            case 1:
              return FlutterDeckCodeHighlight(
                code: buildWasm,
                fileName: "build_wasm.dart",
                textStyle: TextStyle(fontSize: 14),
              );
            case 2:
              return FlutterDeckCodeHighlight(code: allocation, fileName: "wasm.c", textStyle: TextStyle(fontSize: 14));
            case 3:
              return FlutterDeckCodeHighlight(code: load, textStyle: TextStyle(fontSize: 16));
            case 4:
              return FlutterDeckCodeHighlight(code: impl);
            default:
              return SizedBox();
          }
        },
      ),
    );
  }
}
