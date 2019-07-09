//
//  JustFFPlayer.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/4.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "JustPlayerConfigure.h"
#import "JustVideoFrame.h"
#import "JustPlayerTrack.h"

@protocol JustFFmpegPlayerOutput <NSObject>

- (JustVideoFrame *)playerOutputGetVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion
                                                currentDuration:(NSTimeInterval)currentDuration;

@end

@interface JustFFPlayer : NSObject <JustFFmpegPlayerOutput>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;

+ (instancetype)playerWithPlayerConfigure:(JustPlayerManager *)playerConfigure;

@property (nonatomic, weak, readonly) JustPlayerManager *playerConfigure;

@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;

- (void)replaceVideo;
- (void)reloadVolume;

- (void)play;
- (void)pause;
- (void)stop;

@property (nonatomic, assign, readonly) JustPlayerState state;
@property (nonatomic, assign) BOOL seekEnable;
@property (nonatomic, assign, readonly) BOOL seeking;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler;

- (void)selectAudioTrackIndex:(int)audioTrackIndex;

- (void)reloadPlayableBufferInterval;

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) JustPlayerTrack * videoTrack;
@property (nonatomic, strong, readonly) JustPlayerTrack * audioTrack;

@property (nonatomic, strong, readonly) NSArray <JustPlayerTrack *> * videoTracks;
@property (nonatomic, strong, readonly) NSArray <JustPlayerTrack *> * audioTracks;

@end
