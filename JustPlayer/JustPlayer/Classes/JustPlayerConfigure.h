//
//  JustPlayerConfigure.h
//  JustPlayer
//
//  Created by PeachRain on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JustPlayerModels.h"
#import "JustPlayerDecoder.h"
#import "JustImage.h"

// player state
typedef NS_ENUM(NSUInteger, JustPlayerState) {
    JustPlayerStateNone = 0,          // none
    JustPlayerStateBuffering = 1,     // buffering 缓存中
    JustPlayerStateReadyToPlay = 2,   // ready to play
    JustPlayerStatePlaying = 3,       // playing
    JustPlayerStateSuspend = 4,       // pause
    JustPlayerStateFinished = 5,      // finished
    JustPlayerStateFailed = 6,        // failed
};

typedef NS_ENUM(NSUInteger, JustVideoType) {
    JustVideoTypeNormal,  // normal
};

// video content mode
typedef NS_ENUM(NSUInteger, JustGravityMode) {
    JustGravityModeResize,
    JustGravityModeResizeAspect,
    JustGravityModeResizeAspectFill,
};

// background mode
typedef NS_ENUM(NSUInteger, JustPlayerBackgroundMode) {
    JustPlayerBackgroundModeNothing,
    JustPlayerBackgroundModeAutoPlayAndPause,     // default
    JustPlayerBackgroundModeContinue,
};

@interface JustPlayerManager : NSObject

@property (nonatomic, assign, readonly) JustVideoType videoType;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, assign) JustGravityMode viewGravityMode;       // default is JustGravityModeResizeAspect;
@property (nonatomic, assign) JustPlayerBackgroundMode backgroundMode;    // background mode
@property (nonatomic, assign, readonly) JustPlayerState state;
@property (nonatomic, strong, nullable) JustError * error;
@property (nonatomic, strong) JustPlayerDecoder * decoder;

@property (nonatomic, assign) CGFloat volume;                           // default is 1
@property (nonatomic, assign) NSTimeInterval playableBufferInterval;    // default is 2s

@property (nonatomic, copy) void (^viewTapAction)(JustPlayerManager * player, UIView * view);

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL;

+ (instancetype)player;

- (JustImage *)snapshot;

//播放相关
- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void(^)(BOOL finished))completeHandler;


@end
