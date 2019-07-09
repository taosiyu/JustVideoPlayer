//
//  JustPlayerConfigure.m
//  JustPlayer
//
//  Created by PeachRain on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustPlayerConfigure.h"
#import "JustDisplayView.h"
#import "JustAVPlayer.h"
#import "JustFFPlayer.h"
#import "JustPlayerTrack.h"
#import "JustAudioManager.h"

@interface JustPlayerManager ()

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, strong) JustDisplayView * displayView;
@property (nonatomic, assign) JustDecoderType decoderType;
@property (nonatomic, assign) JustVideoType videoType;

@property (nonatomic, strong) JustAVPlayer * avPlayer;
@property (nonatomic, strong) JustFFPlayer * ffmpegPlayer;

@property (nonatomic, assign) BOOL needAutoPlay;
@property (nonatomic, assign) NSTimeInterval lastForegroundTimeInterval;

@end

@implementation JustPlayerManager

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupNotification];
        self.decoder = [JustPlayerDecoder decoderByDefault];
        self.contentURL = nil;
        self.videoType = JustVideoTypeNormal;
        self.backgroundMode = JustPlayerBackgroundModeAutoPlayAndPause;
        self.viewGravityMode = JustGravityModeResizeAspect;
        self.playableBufferInterval = 2.f;
        self.volume = 1;
        self.displayView = [JustDisplayView displayViewWithPlayerConfigure:self];
    }
    return self;
}

#pragma mark - dealloc clean

- (void)cleanPlayer
{
    [self.avPlayer stop];
    self.avPlayer = nil;
    
    [self.ffmpegPlayer stop];
    self.ffmpegPlayer = nil;
    
    [self cleanPlayerView];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    self.needAutoPlay = NO;
    self.error = nil;
}

- (void)cleanPlayerView
{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (void)dealloc
{
    [self cleanPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[JustAudioManager manager] removeHandlerTarget:self];
}

#pragma mark - replace reload

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:JustVideoTypeNormal];
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(JustVideoType)videoType
{
    self.error = nil;
    self.contentURL = contentURL;
    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
    self.videoType = videoType;
    
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
        {
            [self.ffmpegPlayer stop];
    
            if (!self.avPlayer) {
                self.avPlayer = [JustAVPlayer playerWithPlayerConfigure:self];
            }
            [self.avPlayer replaceVideo];
        }
            break;
        case JustDecoderTypeFFmpeg:
        {
            [self.avPlayer stop];

            if (!self.ffmpegPlayer) {
                self.ffmpegPlayer = [JustFFPlayer playerWithPlayerConfigure:self];
            }
            [self.ffmpegPlayer replaceVideo];
        }
            break;
        case JustDecoderTypeError:
        {
            [self.avPlayer stop];
            [self.ffmpegPlayer stop];
        }
            break;
    }
}

#pragma mark - play pause replay

- (void)play
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            [self.avPlayer play];
            break;
        case JustDecoderTypeFFmpeg:
            [self.ffmpegPlayer play];
            break;
        case JustDecoderTypeError:
            break;
    }
}

- (void)pause
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            [self.avPlayer pause];
            break;
        case JustDecoderTypeFFmpeg:
            [self.ffmpegPlayer pause];
            break;
        case JustDecoderTypeError:
            break;
    }
}

- (void)stop
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self replaceVideoWithURL:nil];
}

- (BOOL)seekEnable
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.seekEnable;
            break;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.seekEnable;
        case JustDecoderTypeError:
            return NO;
    }
}

- (BOOL)seeking
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.seeking;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.seeking;
        case JustDecoderTypeError:
            return NO;
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void (^)(BOOL))completeHandler
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            [self.avPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case JustDecoderTypeFFmpeg:
            [self.ffmpegPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case JustDecoderTypeError:
            break;
    }
}

#pragma mark - set get

- (void)setVolume:(CGFloat)volume
{
    _volume = volume;
    [self.avPlayer reloadVolume];
    [self.ffmpegPlayer reloadVolume];
}

- (void)setPlayableBufferInterval:(NSTimeInterval)playableBufferInterval
{
    _playableBufferInterval = playableBufferInterval;
    [self.ffmpegPlayer reloadPlayableBufferInterval];
}

- (void)setViewGravityMode:(JustGravityMode)viewGravityMode
{
    _viewGravityMode = viewGravityMode;
    [self.displayView reloadGravityMode];
}

- (void)setError:(JustError * _Nullable)error
{
    if (self.error != error) {
        self->_error = error;
    }
}

- (JustPlayerState)state
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.state;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.state;
        case JustDecoderTypeError:
            return JustPlayerStateNone;
    }
}

- (CGSize)presentationSize
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.presentationSize;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.presentationSize;
        case JustDecoderTypeError:
            return CGSizeZero;
    }
}

- (NSTimeInterval)progress
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.progress;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.progress;
        case JustDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)duration
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.duration;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.duration;
        case JustDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)playableTime
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.playableTime;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.playableTime;
        case JustDecoderTypeError:
            return 0;
    }
}

- (JustImage *)snapshot
{
    return self.displayView.snapshot;
}

- (UIView *)view
{
    return self.displayView;
}

- (BOOL)videoEnable
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.videoEnable;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.videoEnable;
        case JustDecoderTypeError:
            return NO;
    }
}

- (BOOL)audioEnable
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.audioEnable;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.audioEnable;
        case JustDecoderTypeError:
            return NO;
    }
}

- (JustPlayerTrack *)videoTrack
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.videoTrack;
        case JustDecoderTypeFFmpeg:
            return nil;//self.ffPlayer.videoTrack;
        case JustDecoderTypeError:
            return nil;
    }
}

- (JustPlayerTrack *)audioTrack
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            return self.avPlayer.audioTrack;
        case JustDecoderTypeFFmpeg:
            return self.ffmpegPlayer.audioTrack;
        case JustDecoderTypeError:
            return nil;
    }
}

- (void)selectAudioTrack:(JustPlayerTrack *)audioTrack
{
    [self selectAudioTrackIndex:audioTrack.index];
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    switch (self.decoderType)
    {
        case JustDecoderTypeAVPlayer:
            [self.avPlayer selectAudioTrackIndex:audioTrackIndex];
        case JustDecoderTypeFFmpeg:
            [self.ffmpegPlayer selectAudioTrackIndex:audioTrackIndex];
            break;
        case JustDecoderTypeError:
            break;
    }
}


#pragma mark - background mode notification

- (void)setupNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    __weak typeof(self) weakSelf = self;
            
    JustAudioManager * manager = [JustAudioManager manager];
    [manager setHandlerTarget:self interruption:^(id handlerTarget, JustAudioManager *audioManager, AVAudioSessionInterruptionType type, AVAudioSessionInterruptionOptions option) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (type == AVAudioSessionInterruptionTypeBegan) {
            switch (strongSelf.state) {
                case JustPlayerStatePlaying:
                case JustPlayerStateBuffering:
                {
                    // fix : maybe receive interruption notification when enter foreground.
                    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                    if (timeInterval - strongSelf.lastForegroundTimeInterval > 1.5) {
                        [strongSelf pause];
                    }
                }
                    break;
                default:
                    break;
            }
        }
    } routeChange:^(id handlerTarget, JustAudioManager *audioManager, AVAudioSessionRouteChangeReason reason) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
            switch (strongSelf.state) {
                case JustPlayerStatePlaying:
                case JustPlayerStateBuffering:
                {
                    [strongSelf pause];
                }
                    break;
                default:
                    break;
            }
        }
    }];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case JustPlayerBackgroundModeNothing:
        case JustPlayerBackgroundModeContinue:
            break;
        case JustPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case JustPlayerStatePlaying:
                case JustPlayerStateBuffering:
                {
                    self.needAutoPlay = YES;
                    [self pause];
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case JustPlayerBackgroundModeNothing:
        case JustPlayerBackgroundModeContinue:
            break;
        case JustPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case JustPlayerStateSuspend:
                {
                    if (self.needAutoPlay) {
                        self.needAutoPlay = NO;
                        [self play];
                        self.lastForegroundTimeInterval = [NSDate date].timeIntervalSince1970;
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}

@end












