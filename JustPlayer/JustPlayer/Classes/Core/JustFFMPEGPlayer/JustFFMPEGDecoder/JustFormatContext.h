//
//  JustFormatContext.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustVideoFrame.h"
#import "JustTrack.h"
#import <CoreGraphics/CoreGraphics.h>
#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>

@interface JustFormatContext : NSObject
{
@public
    AVFormatContext * _format_context;
    AVCodecContext * _video_codec_context;
    AVCodecContext * _audio_codec_context;
}

@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) CGSize videoPresentationSize;
@property (nonatomic, assign, readonly) CGFloat videoAspect;

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;
@property (nonatomic, assign, readonly) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readonly) NSTimeInterval audioTimebase;
@property (nonatomic, assign, readonly) NSTimeInterval videoFPS;
@property (nonatomic, assign, readonly) JustVideoFrameRotateType videoFrameRotateType;

@property (nonatomic, strong, readonly) JustTrack * videoTrack;
@property (nonatomic, strong, readonly) JustTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <JustTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <JustTrack *> * audioTracks;

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL;

- (void)setup;
- (void)destroy;

- (BOOL)seekEnable;
- (void)seekWithTimebase:(NSTimeInterval)time;

- (int)readFrame:(AVPacket *)packet;
- (JustVideoFrameRotateType)videoFrameRotateType;

- (BOOL)containAudioTrack:(int)audioTrackIndex;
- (NSError *)selectAudioTrackIndex:(int)audioTrackIndex;

@property (nonatomic, copy, readonly) NSError * error;

@end
