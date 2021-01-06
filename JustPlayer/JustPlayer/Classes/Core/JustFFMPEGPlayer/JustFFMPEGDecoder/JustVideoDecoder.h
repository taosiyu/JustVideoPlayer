//
//  JustVideoDecoder.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustVideoFrame.h"
#import <libavcodec/avcodec.h>

@class JustVideoDecoder;

@protocol JustVideoDecoderDlegate <NSObject>

- (void)videoDecoder:(JustVideoDecoder *)videoDecoder didError:(NSError *)error;
- (void)videoDecoder:(JustVideoDecoder *)videoDecoder didChangePreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond;

@end

@interface JustVideoDecoder : NSObject

@property (nonatomic, weak) id <JustVideoDecoderDlegate> delegate;

@property (nonatomic, assign, readonly) BOOL videoToolBoxEnable;
@property (nonatomic, assign, readonly) BOOL videoToolBoxDidOpen;
@property (nonatomic, assign, readonly) BOOL codecContextAsync;
@property (nonatomic, assign) NSInteger videoToolBoxMaxDecodeFrameCount;     // default is 20.
@property (nonatomic, assign) NSInteger codecContextMaxDecodeFrameCount;     // default is 3.

@property (nonatomic, strong, readonly) NSError * error;
@property (nonatomic, assign, readonly) NSTimeInterval timebase;
@property (nonatomic, assign, readonly) NSTimeInterval fps;
@property (nonatomic, assign, readonly) JustVideoFrameRotateType rotateType;

@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) BOOL empty;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) BOOL decodeSync;
@property (nonatomic, assign, readonly) BOOL decodeAsync;
@property (nonatomic, assign, readonly) BOOL decodeOnMainThread;

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL endOfFile;

- (void)flush;
- (void)destroy;

- (void)startDecodeThread;

- (void)putPacket:(AVPacket)packet;
- (JustVideoFrame *)getFrameAsync;
- (JustVideoFrame *)getFrameAsyncPosistion:(NSTimeInterval)position;

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                                    fps:(NSTimeInterval)fps
                      codecContextAsync:(BOOL)codecContextAsync
                     videoToolBoxEnable:(BOOL)videoToolBoxEnable
                             rotateType:(JustVideoFrameRotateType)rotateType
                               delegate:(id <JustVideoDecoderDlegate>)delegate;

@end
