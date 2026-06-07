
import 'dart:io';

// Export the primary interface blueprint to the consumer
export 'interface.dart';

// Dynamically expose the implementation files based on compiling targets
export 'mic_ffi_io.dart' if (dart.library.js_interop) 'mic_ffi_web.dart';
