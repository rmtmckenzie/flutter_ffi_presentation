#import "AudioMarshaller.h"

@implementation AudioMarshaller {
    DartMainThreadCallback _boundDartCallback;
}

- (instancetype)initWithCallback:(DartMainThreadCallback)dartCallback {
    self = [super init];
    if (self) {
        // Copy the Dart function reference to the heap so it lives as long as this instance lives
        _boundDartCallback = [dartCallback copy];
    }
    return self;
}

- (AVAudioEngineTapBlock)getBridgeBlock {
    // Capture a weak reference to self to prevent retain cycles within the block
    __weak AudioMarshaller *weakSelf = self;

    // Return a native block closure that Apple's hardware thread can execute safely
    return ^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        AudioMarshaller *strongSelf = weakSelf;
        if (strongSelf == nil || buffer.floatChannelData == NULL || buffer.frameLength == 0) return;

        float *channelData = buffer.floatChannelData[0];
        NSInteger frameCount = (NSInteger)buffer.frameLength;

        // 1. Duplicate the memory immediately on the background thread
        float *copiedPointer = (float *)malloc(frameCount * sizeof(float));
        if (copiedPointer == NULL) return;
        memcpy(copiedPointer, channelData, frameCount * sizeof(float));

        // 2. THE HOP: Push the execution block over to Grand Central Dispatch's main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            // 3. Safely invoke Dart on the Main UI thread isolate
            if (strongSelf->_boundDartCallback != nil) {
                strongSelf->_boundDartCallback(copiedPointer, frameCount);
            }
            // 4. Free the copied memory instantly after Dart finishes processing it
            free(copiedPointer);
        });
    };
}

@end