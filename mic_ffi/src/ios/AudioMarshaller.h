#ifndef AudioMarshaller_h
#define AudioMarshaller_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// The final main-thread Dart destination block signature
typedef void (^DartMainThreadCallback)(float * _Nonnull rawSamples, NSInteger frameCount);

// The hardware block signature that AVAudioEngine expects
typedef void (^AVAudioEngineTapBlock)(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when);

@interface AudioMarshaller : NSObject

// Instantiate the marshaller by passing the Dart callback directly to the initializer
- (instancetype _Nonnull)initWithCallback:(DartMainThreadCallback _Nonnull)dartCallback;

// Request a safe native thread-hopping block tied to this instance
- (AVAudioEngineTapBlock _Nonnull)getBridgeBlock;

@end

#endif /* AudioMarshaller_h */