//
//  JustAudioDecoder.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustAudioFrame.h"
#import <libavcodec/avcodec.h>

@class JustAudioDecoder;

@protocol JustAudioDecoderDelegate <NSObject>

//获取相关音频设置数据
- (void)audioDecoder:(JustAudioDecoder *)audioDecoder samplingRate:(Float64 *)samplingRate;
- (void)audioDecoder:(JustAudioDecoder *)audioDecoder channelCount:(UInt32 *)channelCount;

@end

@interface JustAudioDecoder : NSObject

@property (nonatomic, weak) id <JustAudioDecoderDelegate> delegate;

@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) BOOL empty;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context
                               timebase:(NSTimeInterval)timebase
                               delegate:(id<JustAudioDecoderDelegate>)delegate;

- (void)flush;
- (void)destroy;

- (int)putPacket:(AVPacket)packet;
- (JustAudioFrame *)getFrameSync;

@end
