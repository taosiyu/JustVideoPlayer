//
//  JustFFDecoder.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/4.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "JustAudioFrame.h"
#import "JustVideoFrame.h"
#import "JustTrack.h"

@class JustFFDecoder;

@protocol JustFFmpegDecoderDelegate <NSObject>
@optional

- (void)decoderWillOpenInputStream:(JustFFDecoder *)decoder;      // open input stream
- (void)decoderDidPrepareToDecodeFrames:(JustFFDecoder *)decoder;     // prepare decode frames
- (void)decoderDidEndOfFile:(JustFFDecoder *)decoder;     // end of file
- (void)decoderDidPlaybackFinished:(JustFFDecoder *)decoder;
- (void)decoder:(JustFFDecoder *)decoder didError:(NSError *)error;       // error callback

// value change
- (void)decoder:(JustFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering;
- (void)decoder:(JustFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration;
- (void)decoder:(JustFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress;

@end

@protocol JustDecoderAudioOutput <NSObject>

- (JustAudioFrame *)decoderAudioOutputGetAudioFrame;

@end

@protocol JustDecoderVideoOutput <NSObject>

- (JustVideoFrame *)decoderVideoOutputGetVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion
                                                      currentDuration:(NSTimeInterval)currentDuration;

@end

@protocol JustDecoderAudioOutputConfig <NSObject>

- (Float64)decoderAudioOutputConfigGetSamplingRate;
- (UInt32)decoderAudioOutputConfigGetNumberOfChannels;

@end

@protocol JustDecoderVideoOutputConfig <NSObject>

- (void)decoderVideoOutputConfigDidUpdateMaxPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond;
- (BOOL)decoderVideoOutputConfigAVCodecContextDecodeAsync;

@end

@interface JustFFDecoder : NSObject <JustDecoderAudioOutput, JustDecoderVideoOutput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, assign) NSTimeInterval minBufferedDruation;
@property (nonatomic, assign) BOOL hardwareDecodeEnable;       // default is YES;

@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) CGFloat aspect;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval bufferedDuration;

@property (nonatomic, assign, readonly) BOOL buffering;
@property (nonatomic, assign, readonly) BOOL playbackFinished;
@property (atomic, assign, readonly) BOOL closed;
@property (atomic, assign, readonly) BOOL endOfFile;
@property (atomic, assign, readonly) BOOL paused;
@property (atomic, assign, readonly) BOOL seeking;
@property (atomic, assign, readonly) BOOL reading;
@property (atomic, assign, readonly) BOOL prepareToDecode;

@property (nonatomic, assign, readonly) BOOL seekEnable;

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) JustTrack * videoTrack;
@property (nonatomic, strong, readonly) JustTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <JustTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <JustTrack *> * audioTracks;


+ (instancetype)decoderWithContentURL:(NSURL *)contentURL
                             delegate:(id<JustFFmpegDecoderDelegate>)delegate
                    videoOutputConfig:(id<JustDecoderVideoOutputConfig>)videoOutputConfig
                    audioOutputConfig:(id<JustDecoderAudioOutputConfig>)audioOutputConfig;

- (void)selectAudioTrackIndex:(int)audioTrackIndex;




- (void)open;
- (void)closeFile;
- (void)pause;
- (void)resume;

- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler;

@end
