import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class TripleBufferManager {
  final int frameSizeInBytes;

  // Allocate 3 distinct native memory blocks
  late final List<Pointer<Uint8>> _buffers;

  int _writeIndex = 0;  // Handed to Native
  int _middleIndex = 1; // Staging area
  int _readIndex = 2;   // Handed to Dart processing

  bool _hasNewData = false;

  TripleBufferManager(this.frameSizeInBytes) {
    _buffers = [
      malloc.allocate<Uint8>(frameSizeInBytes),
      malloc.allocate<Uint8>(frameSizeInBytes),
      malloc.allocate<Uint8>(frameSizeInBytes),
    ];
  }

  // Pass this pointer to your Obj-C Marshaller initially
  Pointer<Uint8> get currentWritePointer => _buffers[_writeIndex];

  /// Called via your NativeCallable.listener when Obj-C finishes a frame
  Pointer<Uint8> handleNativeFrameCompleted() {
    // 1. Swap the Write buffer with the Middle buffer
    final temp = _writeIndex;
    _writeIndex = _middleIndex;
    _middleIndex = temp;

    _hasNewData = true;

    // 2. Return the NEW write pointer back to Obj-C for the next frame
    return _buffers[_writeIndex];
  }

  /// Called by your Dart processing loop when it wants to read the audio
  Uint8List? consumeLatestFrame() {
    if (!_hasNewData) return null; // No new frame has landed yet

    // Swap the Middle (latest complete data) with the Read buffer
    final temp = _readIndex;
    _readIndex = _middleIndex;
    _middleIndex = temp;

    _hasNewData = false;

    // Return a view of the read buffer.
    // This is safe because Obj-C is now writing to a completely different pointer!
    return _buffers[_readIndex].asTypedList(frameSizeInBytes);
  }

  void dispose() {
    for (var ptr in _buffers) {
      malloc.free(ptr);
    }
  }
}

/*
// AudioMarshaller.h
@interface AudioMarshaller : NSObject

// Function pointer type for the Dart callback
typedef uint8_t* (*FrameFilledCallback)(void);

@property (nonatomic, assign) uint8_t *currentBufferPointer;
@property (nonatomic, assign) FrameFilledCallback onFrameFilled;

- (void)startStreaming;
@end

// AudioMarshaller.m
@implementation AudioMarshaller

// This method simulates your hardware audio engine or CoreAudio callback
- (void)processIncomingAudioHardwareBuffer:(uint8_t *)hardwareBuffer length:(int)length {
    if (self.currentBufferPointer != NULL) {
        // 1. Highly optimized, thread-safe memory copy into Dart's pre-allocated space
        memcpy(self.currentBufferPointer, hardwareBuffer, length);

        // 2. Notify Dart that this buffer is full.
        // The Dart callback handles the triple-buffer swap and instantly
        // returns the pointer to the NEXT available empty block.
        if (self.onFrameFilled != NULL) {
            self.currentBufferPointer = self.onFrameFilled();
        }
    }
}

@end
 */