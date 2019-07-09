//
//  JustFFPlayer.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/4.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustFFPlayer.h"
#import "JustFFDecoder.h"
#import "JustAudioManager.h"
#import "JustPlayerNotification.h"
#import "JustAudioFrame.h"
#import "JustPlayerManager+DisplayView.h"

@interface JustFFPlayer () <JustAudioManagerDelegate,JustFFmpegDecoderDelegate,JustDecoderVideoOutputConfig,JustDecoderAudioOutputConfig>

@property (nonatomic, weak) JustPlayerManager * playerConfigure;
@property (nonatomic, assign) JustPlayerState state;
@property (nonatomic, strong) JustFFDecoder *ffmpegDecoder; //解码器
@property (nonatomic, strong) JustAudioManager * audioManager;

@property (nonatomic, assign) BOOL playing;
@property (nonatomic, strong) NSLock * stateLock;
@property (nonatomic, assign) NSTimeInterval progress;
@property (nonatomic, assign) BOOL prepare;
@property (nonatomic, assign) NSTimeInterval playableTime;

@property (nonatomic, strong) JustAudioFrame * currentAudioFrame;

@property (nonatomic, assign) NSTimeInterval lastPostProgressTime;
@property (nonatomic, assign) NSTimeInterval lastPostPlayableTime;

@end

@implementation JustFFPlayer

#pragma mark - init

+ (instancetype)playerWithPlayerConfigure:(JustPlayerManager *)playerConfigure
{
    return [[self alloc]initWithPlayerConfigure:playerConfigure];
}

- (instancetype)initWithPlayerConfigure:(JustPlayerManager *)playerConfigure
{
    if (self = [super init]) {
        self.playerConfigure = playerConfigure;
        self.playerConfigure.displayView.playerOutputFF = self;
        self.stateLock = [[NSLock alloc] init];
        self.audioManager = [JustAudioManager manager];
        [self.audioManager registerAudioSession];
        
    }
    return self;
}

#pragma mark - clean dealloc

- (void)clean
{
    [self cleanDecoder];
    [self cleanFrame];
    [self cleanPlayer];
}

- (void)cleanPlayer
{
    self.playing = NO;
    self.state = JustPlayerStateNone;
    self.progress = 0;
    self.playableTime = 0;
    self.prepare = NO;
    self.lastPostProgressTime = 0;
    self.lastPostPlayableTime = 0;
    [self.playerConfigure.displayView playerOutputTypeEmpty];
    [self.playerConfigure.displayView rendererTypeEmpty];
}

- (void)cleanFrame
{
    [self.currentAudioFrame stopPlaying];
    self.currentAudioFrame = nil;
}

- (void)cleanDecoder
{
    if (self.ffmpegDecoder) {
        [self.ffmpegDecoder closeFile];
        self.ffmpegDecoder = nil;
    }
}

- (void)dealloc
{
    [self clean];
    [self.audioManager unregisterAudioSession];
}

#pragma mark - function play control

//开始播放
- (void)play
{
    self.playing = YES;
    
    switch (self.state) {
        case JustPlayerStateFinished:
            [self replaceVideo];//重新播放？？？？
            break;
        case JustPlayerStateFailed:
        case JustPlayerStateNone:
        case JustPlayerStateBuffering:
            self.state = JustPlayerStateBuffering;
            break;
        case JustPlayerStateSuspend:
            if (self.ffmpegDecoder.buffering) {
                self.state = JustPlayerStateBuffering;
            } else {
                self.state = JustPlayerStatePlaying;
            }
            break;
        case JustPlayerStateReadyToPlay:
        case JustPlayerStatePlaying:
            self.state = JustPlayerStatePlaying;
            break;
        default:
            break;
    }
}

- (void)pause
{
    self.playing = NO;
    [self.ffmpegDecoder pause];
    
    switch (self.state) {
        case JustPlayerStateNone:
        case JustPlayerStateSuspend:
            break;
        case JustPlayerStateFailed:
        case JustPlayerStateReadyToPlay:
        case JustPlayerStateFinished:
        case JustPlayerStatePlaying:
        case JustPlayerStateBuffering:
        {
            self.state = JustPlayerStateSuspend;
        }
            break;
    }
}

- (void)stop
{
    [self clean];
}

- (void)replaceVideo
{
    [self clean];
    if (!self.playerConfigure.contentURL) return;
    
    [self.playerConfigure.displayView playerOutputTypeFF];
    self.ffmpegDecoder = [JustFFDecoder decoderWithContentURL:self.playerConfigure.contentURL
                                             delegate:self
                                    videoOutputConfig:self
                                    audioOutputConfig:self];
//    self.decoder.formatContextOptions = [self.abstractPlayer.decoder FFmpegFormatContextOptions];
//    self.decoder.codecContextOptions = [self.abstractPlayer.decoder FFmpegCodecContextOptions];
    self.ffmpegDecoder.hardwareDecodeEnable = self.playerConfigure.decoder.hardwareAccelerateEnableForFFmpeg;
    [self.ffmpegDecoder open];
    [self reloadVolume];
    [self reloadPlayableBufferInterval];
}

- (BOOL)seekEnable
{
    return self.ffmpegDecoder.seekEnable;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler
{
    if (!self.ffmpegDecoder.prepareToDecode) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    [self.ffmpegDecoder seekToTime:time completeHandler:completeHandler];
}

#pragma mark - setter getter

- (void)setState:(JustPlayerState)state
{
    [self.stateLock lock];
    if (_state != state) {
        JustPlayerState temp = _state;
        _state = state;
        if (_state != JustPlayerStateFailed) {
            self.playerConfigure.error = nil;
        }
        if (_state == JustPlayerStatePlaying) {
            [self.audioManager playWithDelegate:self];
        } else {
            [self.audioManager pause];
        }
        [JustPlayerNotification postPlayer:self.playerConfigure statePrevious:temp current:_state];
    }
    [self.stateLock unlock];
}

- (void)setProgress:(NSTimeInterval)progress
{
    if (_progress != progress) {
        _progress = progress;
        NSTimeInterval duration = self.duration;
        double percent = [self percentForTime:_progress duration:duration];
        if (_progress <= 0.000001 || _progress == duration) {
            [JustPlayerNotification postPlayer:self.playerConfigure progressPercent:@(percent) current:@(_progress) total:@(duration)];
        } else {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostProgressTime >= 1) {
                self.lastPostProgressTime = currentTime;
                /*
                 if (!self.decoder.seekEnable && duration <= 0) {
                 duration = _progress;
                 }
                 */
                [JustPlayerNotification postPlayer:self.playerConfigure progressPercent:@(percent) current:@(_progress) total:@(duration)];
            }
        }
    }
}

- (void)setPlayableTime:(NSTimeInterval)playableTime
{
    NSTimeInterval duration = self.duration;
    if (playableTime > duration) {
        playableTime = duration;
    } else if (playableTime < 0) {
        playableTime = 0;
    }
    
    if (_playableTime != playableTime) {
        _playableTime = playableTime;
        double percent = [self percentForTime:_playableTime duration:duration];
        if (_playableTime == 0 || _playableTime == duration) {
//            [JustPlayerNotification postPlayer:self.playerConfigure playablePercent:@(percent) current:@(_playableTime) total:@(duration)];
        } else if (!self.ffmpegDecoder.endOfFile && self.ffmpegDecoder.seekEnable) {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostPlayableTime >= 1) {
                self.lastPostPlayableTime = currentTime;
//                [JustPlayerNotification postPlayer:self.playerConfigure playablePercent:@(percent) current:@(_playableTime) total:@(duration)];
            }
        }
    }
}

- (NSTimeInterval)duration
{
    return self.ffmpegDecoder.duration;
}

- (CGSize)presentationSize
{
    if (self.ffmpegDecoder.prepareToDecode) {
        return self.ffmpegDecoder.presentationSize;
    }
    return CGSizeZero;
}

- (NSTimeInterval)bitrate
{
    if (self.ffmpegDecoder.prepareToDecode) {
        return self.ffmpegDecoder.bitrate;
    }
    return 0;
}

- (BOOL)videoEnable
{
    return self.ffmpegDecoder.videoEnable;
}

- (BOOL)audioEnable
{
    return self.ffmpegDecoder.audioEnable;
}

- (JustPlayerTrack *)videoTrack
{
    return [self playerTrackFromFFTrack:self.ffmpegDecoder.videoTrack];
}

- (JustPlayerTrack *)audioTrack
{
    return [self playerTrackFromFFTrack:self.ffmpegDecoder.audioTrack];
}

- (NSArray <JustPlayerTrack *> *)videoTracks
{
    return [self playerTracksFromFFTracks:self.ffmpegDecoder.videoTracks];
}

- (NSArray <JustPlayerTrack *> *)audioTracks
{
    return [self playerTracksFromFFTracks:self.ffmpegDecoder.audioTracks];;
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    [self.ffmpegDecoder selectAudioTrackIndex:audioTrackIndex];
}

- (JustPlayerTrack *)playerTrackFromFFTrack:(JustTrack *)track
{
    if (track) {
        JustPlayerTrack * obj = [[JustPlayerTrack alloc] init];
        obj.index = track.index;
        obj.name = track.metadata.language;
        return obj;
    }
    return nil;
}

- (NSArray <JustPlayerTrack *> *)playerTracksFromFFTracks:(NSArray <JustTrack *> *)tracks
{
    NSMutableArray <JustPlayerTrack *> * array = [NSMutableArray array];
    for (JustTrack * obj in tracks) {
        JustPlayerTrack * track = [self playerTrackFromFFTrack:obj];
        [array addObject:track];
    }
    if (array.count > 0) {
        return array;
    }
    return nil;
}

#pragma mark - private function

- (void)reloadVolume
{
    self.audioManager.volume = self.playerConfigure.volume;
}

- (void)reloadPlayableBufferInterval
{
    self.ffmpegDecoder.minBufferedDruation = self.playerConfigure.playableBufferInterval;
}

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

#pragma mark - delegate

//JustFFmpegDecoderDelegate

- (void)decoderWillOpenInputStream:(JustFFDecoder *)decoder
{
    self.state = JustPlayerStateBuffering;
}

- (void)decoderDidPrepareToDecodeFrames:(JustFFDecoder *)decoder
{
    if (self.ffmpegDecoder.videoEnable) {
        [self.playerConfigure.displayView rendererTypeOpenGL];
    }
}

- (void)decoderDidEndOfFile:(JustFFDecoder *)decoder
{
    self.playableTime = self.duration;
}

- (void)decoderDidPlaybackFinished:(JustFFDecoder *)decoder
{
    self.state = JustPlayerStateFinished;
}

- (void)decoder:(JustFFDecoder *)decoder didError:(NSError *)error
{
    [self errorHandler:error];
}

- (void)decoder:(JustFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering
{
    if (buffering) {
        self.state = JustPlayerStateBuffering;
    } else {
        if (self.playing) {
            self.state = JustPlayerStatePlaying;
        } else if (!self.prepare) {
            self.state = JustPlayerStateReadyToPlay;
            self.prepare = YES;
        } else {
            self.state = JustPlayerStateSuspend;
        }
    }
}

- (void)decoder:(JustFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration
{
    self.playableTime = self.progress + bufferedDuration;
}

- (void)decoder:(JustFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress
{
    self.progress = progress;
}

- (void)errorHandler:(NSError *)error
{
    JustError * obj = [[JustError alloc] init];
    obj.error = error;
    self.playerConfigure.error = obj;
    self.state = JustPlayerStateFailed;
    [JustPlayerNotification postNotificationPlayer:self.playerConfigure error:obj];
}

//JustFFmpegPlayerOutput
- (JustVideoFrame *)playerOutputGetVideoFrameWithCurrentPostion:(NSTimeInterval)currentPostion
                                                currentDuration:(NSTimeInterval)currentDuration
{
    if (self.ffmpegDecoder) {
        return [self.ffmpegDecoder decoderVideoOutputGetVideoFrameWithCurrentPostion:currentPostion
                                                               currentDuration:currentDuration];
    }
    return nil;
}

//JustDecoderVideoOutputConfig
- (void)decoderVideoOutputConfigDidUpdateMaxPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    
}

- (BOOL)decoderVideoOutputConfigAVCodecContextDecodeAsync
{
    return YES;
}

//JustDecoderAudioOutputConfig
- (Float64)decoderAudioOutputConfigGetSamplingRate
{
    return self.audioManager.samplingRate;
}

- (UInt32)decoderAudioOutputConfigGetNumberOfChannels
{
    return self.audioManager.numberOfChannels;
}

//JustAudioManagerDelegate
//获取和填充音频数据给device播放
- (void)audioManager:(JustAudioManager *)audioManager
          outputData:(float *)outputData
      numberOfFrames:(UInt32)numberOfFrames
    numberOfChannels:(UInt32)numberOfChannels
{
    if (!self.playing) {
        //清空数据
        memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
        return;
    }
    @autoreleasepool
    {
        while (numberOfFrames > 0)
        {
            if (!self.currentAudioFrame) {
                self.currentAudioFrame = [self.ffmpegDecoder decoderAudioOutputGetAudioFrame];
                [self.currentAudioFrame startPlaying];
            }
            if (!self.currentAudioFrame) {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                return;
            }
            
            const Byte * bytes = (Byte *)self.currentAudioFrame->samples + self.currentAudioFrame->output_offset;
            const NSUInteger bytesLeft = self.currentAudioFrame->length - self.currentAudioFrame->output_offset;
            const NSUInteger frameSizeOf = numberOfChannels * sizeof(float);
            const NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
            const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfFrames -= framesToCopy;
            outputData += framesToCopy * numberOfChannels;
            
            if (bytesToCopy < bytesLeft) {
                self.currentAudioFrame->output_offset += bytesToCopy;
            } else {
                [self.currentAudioFrame stopPlaying];
                self.currentAudioFrame = nil;
            }
        }
    }
}

@end
























