//
//  JustAudioManager.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/17.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class JustAudioManager;
//音频打断回调block
typedef void (^JustAudioManagerInterruptionHandler)(id handlerTarget, JustAudioManager * audioManager, AVAudioSessionInterruptionType type, AVAudioSessionInterruptionOptions option);

typedef void (^JustAudioManagerRouteChangeHandler)(id handlerTarget, JustAudioManager * audioManager, AVAudioSessionRouteChangeReason reason);

@protocol JustAudioManagerDelegate <NSObject>
- (void)audioManager:(JustAudioManager *)audioManager outputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels;
@end

@interface JustAudioManager : NSObject

@property (nonatomic, weak, readonly) id <JustAudioManagerDelegate> delegate;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)manager;

@property (nonatomic, assign) float volume;

@property (nonatomic, assign, readonly) BOOL playing;
@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) UInt32 numberOfChannels;

- (void)setHandlerTarget:(id)handlerTarget
            interruption:(JustAudioManagerInterruptionHandler)interruptionHandler
             routeChange:(JustAudioManagerRouteChangeHandler)routeChangeHandler;
- (void)removeHandlerTarget:(id)handlerTarget;

- (BOOL)setupAudioUnit;
- (BOOL)registerAudioSession;
- (void)unregisterAudioSession;

- (void)playWithDelegate:(id <JustAudioManagerDelegate>)delegate;
- (void)pause;

@end
