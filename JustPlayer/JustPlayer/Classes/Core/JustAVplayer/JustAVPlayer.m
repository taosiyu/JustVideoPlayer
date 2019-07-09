//
//  JustAVPlayer.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustAVPlayer.h"
#import "JustImage.h"
#import "JustPlayerModels.h"
#import "JustPlayerManager+DisplayView.h"
#import "JustPlayerNotification.h"

static CGFloat const PixelBufferRequestInterval = 0.03f;
static NSString * const AVMediaSelectionOptionTrackIDKey = @"MediaSelectionOptionsPersistentID";

@interface JustAVPlayer ()

@property (nonatomic, weak) JustPlayerManager * playerConfigure;

@property (nonatomic, assign) JustPlayerState state;
@property (nonatomic, assign) JustPlayerState stateBeforBuffering;

@property (atomic, strong) id playBackTimeObserver;

@property (nonatomic, strong) AVPlayer * avPlayer;
@property (nonatomic, strong) AVPlayerItem * avPlayerItem;
@property (atomic, strong) AVURLAsset * avAsset;
@property (atomic, strong) AVPlayerItemVideoOutput * avOutput;
@property (atomic, assign) NSTimeInterval readyToPlayTime;
@property (nonatomic, assign) NSTimeInterval playableTime;

@property (atomic, assign) BOOL playing;
@property (atomic, assign) BOOL buffering;
@property (atomic, assign) BOOL hasPixelBuffer;
@property (nonatomic, assign) BOOL seeking;

@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, assign) BOOL audioEnable;
@property (nonatomic, strong) NSArray <JustPlayerTrack *> * videoTracks;
@property (nonatomic, strong) NSArray <JustPlayerTrack *> * audioTracks;
@property (nonatomic, strong) JustPlayerTrack * videoTrack;
@property (nonatomic, strong) JustPlayerTrack * audioTrack;

@end

@implementation JustAVPlayer

#pragma mark - init

+ (instancetype)playerWithPlayerConfigure:(JustPlayerManager *)playerConfigure
{
    return [[self alloc]initWithPlayerConfigure:playerConfigure];
}

- (instancetype)initWithPlayerConfigure:(JustPlayerManager *)playerConfigure
{
    if (self = [super init]) {
        self.playerConfigure = playerConfigure;
        self.playerConfigure.displayView.playerOutputAV = self;
    }
    return self;
}

#pragma mark - dealloc

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self replaceEmpty];
    [self cleanAVPlayer];
}

//清理输出
- (void)cleanOutput
{
    if (self.avPlayerItem) {
        [self.avPlayerItem removeOutput:self.avOutput];
    }
    self.avOutput = nil;
    self.hasPixelBuffer = NO;
}

//清理avplayeritem
- (void)cleanAVPlayerItem
{
    if (self.avPlayerItem) {
        [self.avPlayerItem cancelPendingSeeks];
        [self.avPlayerItem removeObserver:self forKeyPath:@"status"];
        [self.avPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.avPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.avPlayerItem removeOutput:self.avOutput];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayerItem];
        self.avPlayerItem = nil;
    }
}

- (void)cleanTrackInfo
{
    self.videoEnable = NO;
    self.videoTrack = nil;
    self.videoTracks = nil;
    
    self.audioEnable = NO;
    self.audioTrack = nil;
    self.audioTracks = nil;
}


//清理avplayer
- (void)cleanAVPlayer
{
    [self.avPlayer pause];
    [self.avPlayer cancelPendingPrerolls];
    [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
    
    if (self.playBackTimeObserver) {
        [self.avPlayer removeTimeObserver:self.playBackTimeObserver];
        self.playBackTimeObserver = nil;
    }
    self.avPlayer = nil;
    [self.playerConfigure.displayView reloadPlayerConfig];
}

- (void)replaceEmpty
{
    [JustPlayerNotification postPlayer:self.playerConfigure progressPercent:@(0) current:@(0) total:@(0)];
    [self.avAsset cancelLoading];
    self.avAsset = nil;
    [self cleanOutput];
    [self cleanAVPlayerItem];
    [self cleanAVPlayer];
    [self cleanTrackInfo];
    self.state = JustPlayerStateNone;
    self.stateBeforBuffering = JustPlayerStateNone;
    self.seeking = NO;
    self.playableTime = 0;
    self.readyToPlayTime = 0;
    self.buffering = NO;
    self.playing = NO;
}

- (void)replaceVideo
{
    [self replaceEmpty];
    if (!self.playerConfigure.contentURL) return;
    
    [self.playerConfigure.displayView playerOutputTypeAVPlayer];
    [self startBuffering];
    self.avAsset = [AVURLAsset assetWithURL:self.playerConfigure.contentURL];
    [self setupAVPlayerItemAutoLoadedAsset:YES];
    [self setupAVPlayer];
    [self.playerConfigure.displayView rendererTypeAVPlayerLayer];
}

#pragma mark - function play control

//开始播放
- (void)play
{
    self.playing = YES;
    
    switch (self.state) {
        case JustPlayerStateFinished:
            [self.avPlayer seekToTime:kCMTimeZero];
            self.state = JustPlayerStatePlaying;
            break;
        case JustPlayerStateFailed:
            [self replaceEmpty];
            [self replaceVideo];
            break;
        case JustPlayerStateNone:
            self.state = JustPlayerStateBuffering;
            break;
        case JustPlayerStateSuspend:
            if (self.buffering) {
                self.state = JustPlayerStateBuffering;
            } else {
                self.state = JustPlayerStatePlaying;
            }
            break;
        case JustPlayerStateReadyToPlay:
            self.state = JustPlayerStatePlaying;
            break;
        default:
            break;
    }
    
    [self.avPlayer play];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        switch (self.state) {
            case JustPlayerStateBuffering:
            case JustPlayerStatePlaying:
            case JustPlayerStateReadyToPlay:
                [self.avPlayer play];
            default:
                break;
        }
    });
}

- (void)pause
{
    [self.avPlayer pause];
    self.playing = NO;
    if (self.state == JustPlayerStateFailed) return;
    self.state = JustPlayerStateSuspend;
}

- (BOOL)seekEnable
{
    if (self.duration <= 0 || self.avPlayerItem.status != AVPlayerItemStatusReadyToPlay) {
        return NO;
    }
    return YES;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL))completeHandler
{
    if (!self.seekEnable || self.avPlayerItem.status != AVPlayerItemStatusReadyToPlay) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.seeking = YES;
        [self startBuffering];
        __weak typeof(self) weakSelf = self;
        [self.avPlayerItem seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                self.seeking = NO;
                [strongSelf stopBuffering];
                [strongSelf resumeStateAfterBuffering];
                if (completeHandler) {
                    completeHandler(finished);
                }
                NSLog(@"JustAVPlayer seek success");
            });
        }];
    });
}

- (void)stop
{
    [self replaceEmpty];
}

//开始缓冲
- (void)startBuffering
{
    if (self.playing) {
        [self.avPlayer pause];
    }
    self.buffering = YES;
    if (self.state != JustPlayerStateBuffering) {
        self.stateBeforBuffering = self.state;
    }
    self.state = JustPlayerStateBuffering;
}

//停止缓冲
- (void)stopBuffering
{
    self.buffering = NO;
}

- (BOOL)playIfNeed
{
    if (self.playing) {
        [self.avPlayer play];
        self.state = JustPlayerStatePlaying;
        return YES;
    }
    return NO;
}

- (void)resumeStateAfterBuffering
{
    if (self.playing) {
        [self.avPlayer play];
        self.state = JustPlayerStatePlaying;
    } else if (self.state == JustPlayerStateBuffering) {
        self.state = self.stateBeforBuffering;
    }
}

#pragma mark - 设置output
- (void)setupOutput
{
    [self cleanOutput];
    
    NSDictionary * pixelBuffer = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};//yuv420
    self.avOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffer];
    [self.avOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:PixelBufferRequestInterval];
    [self.avPlayerItem addOutput:self.avOutput];
    
    NSLog(@"JustAVPlayer add output success");
}

- (void)setupTrackInfo
{
    if (self.videoEnable || self.audioEnable) return;
    
    NSMutableArray <JustPlayerTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <JustPlayerTrack *> * audioTracks = [NSMutableArray array];
    
    for (AVAssetTrack * obj in self.avAsset.tracks) {
        if ([obj.mediaType isEqualToString:AVMediaTypeVideo]) {
            self.videoEnable = YES;
            [videoTracks addObject:[self playerTrackFromAVTrack:obj]];
        } else if ([obj.mediaType isEqualToString:AVMediaTypeAudio]) {
            self.audioEnable = YES;
            [audioTracks addObject:[self playerTrackFromAVTrack:obj]];
        }
    }
    
    if (videoTracks.count > 0) {
        self.videoTracks = videoTracks;
        AVMediaSelectionGroup * videoGroup = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicVisual];
        if (videoGroup) {
            int trackID = [[videoGroup.defaultOption.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            for (JustPlayerTrack * obj in self.audioTracks) {
                if (obj.index == (int)trackID) {
                    self.videoTrack = obj;
                }
            }
            if (!self.videoTrack) {
                self.videoTrack = self.videoTracks.firstObject;
            }
        } else {
            self.videoTrack = self.videoTracks.firstObject;
        }
    }
    if (audioTracks.count > 0) {
        self.audioTracks = audioTracks;
        AVMediaSelectionGroup * audioGroup = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if (audioGroup) {
            int trackID = [[audioGroup.defaultOption.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            for (JustPlayerTrack * obj in self.audioTracks) {
                if (obj.index == (int)trackID) {
                    self.audioTrack = obj;
                }
            }
            if (!self.audioTrack) {
                self.audioTrack = self.audioTracks.firstObject;
            }
        } else {
            self.audioTrack = self.audioTracks.firstObject;
        }
    }
}

#pragma mark - observe play state change
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.avPlayerItem) {
        if ([keyPath isEqualToString:@"status"])
        {
            switch (self.avPlayerItem.status) {
                case AVPlayerItemStatusUnknown:
                {
                    [self startBuffering];
                    NSLog(@"item status unknown");
                }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
                    [self stopBuffering];
                    [self setupTrackInfo];
                    NSLog(@"item status ready to play");
                    self.readyToPlayTime = [NSDate date].timeIntervalSince1970;
                    if (![self playIfNeed]) {
                        switch (self.state) {
                            case JustPlayerStateSuspend:
                            case JustPlayerStateFinished:
                            case JustPlayerStateFailed:
                                break;
                            default:
                                self.state = JustPlayerStateReadyToPlay;
                                break;
                        }
                    }
                }
                    break;
                case AVPlayerItemStatusFailed:
                {
                    NSLog(@"JustAVPlayer item status failed");
                    [self stopBuffering];
                    self.readyToPlayTime = 0;
                    JustError * error = [[JustError alloc] init];
                    if (self.avPlayerItem.error) {
                        error.error = self.avPlayerItem.error;
                        if (self.avPlayerItem.errorLog.extendedLogData.length > 0) {
                            error.extendedLogData = self.avPlayerItem.errorLog.extendedLogData;
                            error.extendedLogDataStringEncoding = self.avPlayerItem.errorLog.extendedLogDataStringEncoding;
                        }
                        if (self.avPlayerItem.errorLog.events.count > 0) {
                            NSMutableArray <JustErrorEvent *> * array = [NSMutableArray arrayWithCapacity:self.avPlayerItem.errorLog.events.count];
                            for (AVPlayerItemErrorLogEvent * obj in self.avPlayerItem.errorLog.events) {
                                JustErrorEvent * event = [[JustErrorEvent alloc] init];
                                event.date = obj.date;
                                event.URI = obj.URI;
                                event.serverAddress = obj.serverAddress;
                                event.playbackSessionID = obj.playbackSessionID;
                                event.errorStatusCode = obj.errorStatusCode;
                                event.errorDomain = obj.errorDomain;
                                event.errorComment = obj.errorComment;
                                [array addObject:event];
                            }
                            error.errorEvents = array;
                        }
                    } else if (self.avPlayer.error) {
                        error.error = self.avPlayer.error;
                    } else {
                        error.error = [NSError errorWithDomain:@"AVPlayer playback error" code:-1 userInfo:nil];
                    }
                    self.playerConfigure.error = error;
                    self.state = JustPlayerStateFailed;
                    [JustPlayerNotification postNotificationPlayer:self.playerConfigure error:error];
                }
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (self.avPlayerItem.playbackBufferEmpty) {
                [self startBuffering];
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            [self reloadPlayableTime];
            NSTimeInterval interval = self.playableTime - self.progress;
            NSTimeInterval residue = self.duration - self.progress;
            if (residue <= -1.5) {
                residue = 2;
            }
            if (interval > self.playerConfigure.playableBufferInterval) {
                [self stopBuffering];
                [self resumeStateAfterBuffering];
            } else if (interval < 0.3 && residue > 1.5) {
                [self startBuffering];
            }
        }
    }
}

#pragma mark - set get

- (NSTimeInterval)progress
{
    CMTime currentTime = self.avPlayerItem.currentTime;
    Boolean indefinite = CMTIME_IS_INDEFINITE(currentTime);
    Boolean invalid = CMTIME_IS_INVALID(currentTime);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.avPlayerItem.currentTime);
}

- (NSTimeInterval)duration
{
    CMTime duration = self.avPlayerItem.duration;
    Boolean indefinite = CMTIME_IS_INDEFINITE(duration);
    Boolean invalid = CMTIME_IS_INVALID(duration);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.avPlayerItem.duration);;
}

- (CGSize)presentationSize
{
    if (self.avPlayerItem) {
        return self.avPlayerItem.presentationSize;
    }
    return CGSizeZero;
}

- (void)setState:(JustPlayerState)state
{
    if (_state != state) {
        JustPlayerState temp = _state;
        _state = state;
        switch (self.state) {
            case JustPlayerStateFinished:
                self.playing = NO;
                break;
            case JustPlayerStateFailed:
                self.playing = NO;
                break;
            default:
                break;
        }
        if (_state != JustPlayerStateFailed) {
            self.playerConfigure.error = nil;
        }
        NSLog(@"JustPlayerState temp = %li",temp);
        [JustPlayerNotification postPlayer:self.playerConfigure statePrevious:temp current:_state];
    }
}

- (void)setPlayableTime:(NSTimeInterval)playableTime
{
    if (_playableTime != playableTime) {
        _playableTime = playableTime;
        CGFloat duration = self.duration;
        double percent = [self percentForTime:_playableTime duration:duration];
        NSLog(@"percent = %f",percent);
//        [JustPlayerNotification postPlayer:self.playerConfigure playablePercent:@(percent) current:@(playableTime) total:@(duration)];
    }
}

//加载声音音量
- (void)reloadVolume
{
    self.avPlayer.volume = self.playerConfigure.volume;
}

//重置时间 
- (void)reloadPlayableTime
{
    if (self.avPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        CMTimeRange range = [self.avPlayerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
        if (CMTIMERANGE_IS_VALID(range)) {
            NSTimeInterval start = CMTimeGetSeconds(range.start);
            NSTimeInterval duration = CMTimeGetSeconds(range.duration);
            self.playableTime = (start + duration);
        }
    } else {
        self.playableTime = 0;
    }
}

#pragma mark - avplayer init

#pragma mark - 设置初始化avplayer
- (void)setupAVPlayer
{
    self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];

    __weak typeof(self) weakSelf = self;
    self.playBackTimeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.state == JustPlayerStatePlaying) {
            CGFloat current = CMTimeGetSeconds(time);
            CGFloat duration = strongSelf.duration;
            double percent = [strongSelf percentForTime:current duration:duration];
            NSLog(@"percent = %f",percent);
            [JustPlayerNotification postPlayer:strongSelf.playerConfigure progressPercent:@(percent) current:@(current) total:@(duration)];
        }
    }];
    [self.playerConfigure.displayView reloadPlayerConfig];
    [self reloadVolume];
}

//初始化avplayeritem
- (void)setupAVPlayerItemAutoLoadedAsset:(BOOL)autoLoadedAsset
{
    if (autoLoadedAsset) {
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset automaticallyLoadedAssetKeys:[self.class AVAssetloadKeys]];
    } else {
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset];
    }
    
    [self.avPlayerItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
    [self.avPlayerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:NULL];
    [self.avPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avplayerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayerItem];
}

#pragma mark - JustAVPlayerOutput

- (AVPlayer *)playerOutputGetAVPlayer
{
    return self.avPlayer;
}

- (CVPixelBufferRef)playerOutputGetPixelBufferAtCurrentTime
{
    if (self.seeking) return nil;
    
    BOOL hasNewPixelBuffer = [self.avOutput hasNewPixelBufferForItemTime:self.avPlayerItem.currentTime];
    if (!hasNewPixelBuffer) {
        if (self.hasPixelBuffer) return nil;
        [self trySetupOutput];
        return nil;
    }
    
    CVPixelBufferRef pixelBuffer = [self.avOutput copyPixelBufferForItemTime:self.avPlayerItem.currentTime itemTimeForDisplay:nil];
    if (!pixelBuffer) {
        [self trySetupOutput];
    } else {
        self.hasPixelBuffer = YES;
    }
    return pixelBuffer;
}

//闪照
- (JustImage *)playerOutputGetSnapshotAtCurrentTime
{
    AVAssetImageGenerator * imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.avAsset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSError * error = nil;
    CMTime time = self.avPlayerItem.currentTime;
    CMTime actualTime;
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    JustImage * image = JustGetImageWithCGImage(cgImage);
    return image;
}

#pragma mark - 尝试重新初始化avplayeritem
- (void)trySetupOutput
{
    BOOL isReadyToPlay = self.avPlayerItem.status == AVPlayerStatusReadyToPlay && self.readyToPlayTime > 10 && (([NSDate date].timeIntervalSince1970 - self.readyToPlayTime) > 0.3);
    if (isReadyToPlay) {
        [self setupOutput];
    }
}

#pragma mark - function

- (double)percentForTime:(NSTimeInterval)time duration:(NSTimeInterval)duration
{
    double percent = 0;
    if (time > 0) {
        if (duration <= 0) {
            percent = 1;
        } else {
            percent = time / duration;
        }
    }
    return percent;
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    if (self.audioTrack.index == audioTrackIndex) return;
    AVMediaSelectionGroup * group = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    if (group) {
        for (AVMediaSelectionOption * option in group.options) {
            int trackID = [[option.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            if (audioTrackIndex == trackID) {
                [self.avPlayerItem selectMediaOption:option inMediaSelectionGroup:group];
                for (JustPlayerTrack * track in self.audioTracks) {
                    if (track.index == audioTrackIndex) {
                        self.audioTrack = track;
                        break;
                    }
                }
                break;
            }
        }
    }
}

- (JustPlayerTrack *)playerTrackFromAVTrack:(AVAssetTrack *)track
{
    if (track) {
        JustPlayerTrack * obj = [[JustPlayerTrack alloc] init];
        obj.index = (int)track.trackID;
        obj.name = track.languageCode;
        return obj;
    }
    return nil;
}

#pragma mark - notification

- (void)avplayerItemDidPlayToEnd:(NSNotification *)notification
{
    self.state = JustPlayerStateFinished;
}

#pragma mark - lazy
+ (NSArray <NSString *> *)AVAssetloadKeys
{
    static NSArray * keys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys =@[@"tracks", @"playable"];
    });
    return keys;
}


@end
