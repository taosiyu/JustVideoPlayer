//
//  JustFormatContext.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustFormatContext.h"
#import "JustTools.h"
#import "JustMetadata.h"

@interface JustFormatContext ()

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy) NSDictionary * metadata; //元数据，资源信息

@property (nonatomic, copy) NSError * error;

@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, assign) BOOL audioEnable;

@property (nonatomic, strong) JustTrack * videoTrack;
@property (nonatomic, strong) JustTrack * audioTrack;

@property (nonatomic, strong) NSArray <JustTrack *> * videoTracks;
@property (nonatomic, strong) NSArray <JustTrack *> * audioTracks;

@property (nonatomic, assign) NSTimeInterval videoTimebase;
@property (nonatomic, assign) NSTimeInterval audioTimebase;

@property (nonatomic, assign) NSTimeInterval videoFPS;
@property (nonatomic, assign) CGSize videoPresentationSize;
@property (nonatomic, assign) CGFloat videoAspect;


@end

@implementation JustFormatContext

#pragma mark - init

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL
{
    return [[self alloc] initWithContentURL:contentURL];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL
{
    if (self = [super init])
    {
        self.contentURL = contentURL;
    }
    return self;
}

#pragma mark - dealloc

- (void)destroyAudioTrack
{
    self.audioEnable = NO;
    self.audioTrack = nil;
    self.audioTracks = nil;
    
    if (_audio_codec_context)
    {
        avcodec_close(_audio_codec_context);
        _audio_codec_context = NULL;
    }
}

- (void)destroyVideoTrack
{
    self.videoEnable = NO;
    self.videoTrack = nil;
    self.videoTracks = nil;
    
    if (_video_codec_context)
    {
        avcodec_close(_video_codec_context);
        _video_codec_context = NULL;
    }
}

- (void)destroy
{
    [self destroyVideoTrack];
    [self destroyAudioTrack];
    if (_format_context)
    {
        avformat_close_input(&_format_context);
        _format_context = NULL;
    }
}

- (void)dealloc
{
    [self destroy];
}

#pragma mark - setup

- (void)setup
{
    
    self.error = [self openStream];
    if (self.error)
    {
        return;
    }
    
    [self openTracks];
    NSError * videoError = [self openVideoTrack];
    NSError * audioError = [self openAudioTrack];
    
    if (videoError && audioError)
    {
        if (videoError.code == 3 && audioError.code != 3)
        {
            self.error = audioError;
        }
        else
        {
            self.error = videoError;
        }
        return;
    }
}

//打开数据流
- (NSError *)openStream
{
    int reslut = 0;
    NSError * error = nil;
    
    //初始化上下文
    self->_format_context = avformat_alloc_context();
    if (!_format_context)
    {
        reslut = -1;
        error = [NSError errorWithDomain:@"JustDecoderCodeFormatCreate error" code:JustDecoderErrorCodeFormatCreate userInfo:nil];
        return error;
    }
    
//    _format_context->interrupt_callback.callback = ffmpeg_interrupt_callback;
//    _format_context->interrupt_callback.opaque = (__bridge void *)self;
    
    AVDictionary * options = Just_FFMPEGNSDictionaryToAVDictionary(nil);
    
    // options filter.
    NSString * URLString = [self contentURLString];
    NSString * lowercaseURLString = [URLString lowercaseString];
    if ([lowercaseURLString hasPrefix:@"rtmp"] || [lowercaseURLString hasPrefix:@"rtsp"]) {
        av_dict_set(&options, "timeout", NULL, 0);
    }
    
    //设置输入上下文
    reslut = avformat_open_input(&_format_context, URLString.UTF8String, NULL, &options);
    if (options) {
        av_dict_free(&options);
    }
    if (reslut < 0) {
        if (_format_context)
        {
            avformat_free_context(_format_context);
        }
        error = [NSError errorWithDomain:@"JustDecoderCodeFormatOpenInput error" code:JustDecoderErrorCodeFormatOpenInput userInfo:nil];
        return error;
    }
    
    //读媒体文件的包(packets)，然后从中提取出流的信息
    reslut = avformat_find_stream_info(_format_context, NULL);
    if (reslut < 0) {
        if (_format_context)
        {
            avformat_free_context(_format_context);
        }
        error = [NSError errorWithDomain:@"JustDecoderErrorCodeFormatFindStreamInfo error" code:JustDecoderErrorCodeFormatFindStreamInfo userInfo:nil];
        return error;
    }
    
    self.metadata = Just_FFMPEGAVDictionaryToNSDictionary(_format_context->metadata);
    return error;
}

- (void)openTracks
{
    NSMutableArray <JustTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <JustTrack *> * audioTracks = [NSMutableArray array];
    
    for (int i = 0; i < _format_context->nb_streams; i++)
    {
        AVStream * stream = _format_context->streams[i];
        switch (stream->codecpar->codec_type)
        {
            case AVMEDIA_TYPE_VIDEO:
            {
                JustTrack * track = [[JustTrack alloc] init];
                track.type = JustTrackTypeVideo;
                track.index = i;
                track.metadata = [JustMetadata metadataWithAVDictionary:stream->metadata];
                [videoTracks addObject:track];
            }
                break;
            case AVMEDIA_TYPE_AUDIO:
            {
                JustTrack * track = [[JustTrack alloc] init];
                track.type = JustTrackTypeAudio;
                track.index = i;
                track.metadata = [JustMetadata metadataWithAVDictionary:stream->metadata];
                [audioTracks addObject:track];
            }
                break;
            default:
                break;
        }
    }
    
    if (videoTracks.count > 0)
    {
        self.videoTracks = videoTracks;
    }
    if (audioTracks.count > 0)
    {
        self.audioTracks = audioTracks;
    }
}

//打开视频对应的解码器
- (NSError *)openVideoTrack
{
    NSError * error = nil;
    
    if (self.videoTracks.count > 0)
    {
        for (JustTrack * obj in self.videoTracks)
        {
            int index = obj.index;
            if ((_format_context->streams[index]->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0)
            {
                AVCodecContext * codec_context;
                //获取解码器
                error = [self openStreamWithTrackIndex:index codecContext:&codec_context domain:@"video"];
                if (!error)
                {
                    self.videoTrack = obj;
                    self.videoEnable = YES;
                    self.videoTimebase = Just_FFMPEGStreamGetTimebase(_format_context->streams[index], 0.00004);
                    self.videoFPS = Just_FFMPEGStreamGetFPS(_format_context->streams[index], self.videoTimebase);   //FPS
                    self.videoPresentationSize = CGSizeMake(codec_context->width, codec_context->height);           //图像尺寸
                    self.videoAspect = (CGFloat)codec_context->width / (CGFloat)codec_context->height;              //缩放比例
                    self->_video_codec_context = codec_context;
                    break;
                }
            }
        }
    }
    else
    {
        error = [NSError errorWithDomain:@"video stream not found" code:JustDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

//打开音频对应的解码器
- (NSError *)openAudioTrack
{
    NSError * error = nil;
    
    if (self.audioTracks.count > 0)
    {
        for (JustTrack * obj in self.audioTracks)
        {
            int index = obj.index;
            AVCodecContext * codec_context;
            error = [self openStreamWithTrackIndex:index codecContext:&codec_context domain:@"audio"];
            if (!error)
            {
                self.audioTrack = obj;
                self.audioEnable = YES;
                self.audioTimebase = Just_FFMPEGStreamGetTimebase(_format_context->streams[index], 0.000025);
                self->_audio_codec_context = codec_context;
                break;
            }
        }
    }
    else
    {
        error = [NSError errorWithDomain:@"audio stream not found" code:JustDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openStreamWithTrackIndex:(int)trackIndex codecContext:(AVCodecContext **)codecContext domain:(NSString *)domain
{
    int result = 0;
    NSError * error = nil;
    
    //1.获取steam 流
    AVStream * stream = _format_context->streams[trackIndex];
    //2.初始化解码器上下文
    AVCodecContext * codec_context = avcodec_alloc_context3(NULL);
    if (!codec_context)
    {
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@ codec context create error", domain]
                                    code:JustDecoderErrorCodeCodecContextCreate
                                userInfo:nil];
        return error;
    }
    
    //3.将流中解码器信息复制到新建解码器上下文中
    result = avcodec_parameters_to_context(codec_context, stream->codecpar);
    if (result < 0)
    {
        char * error_string_buffer = malloc(256);
        av_strerror(result, error_string_buffer, 256);
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"ffmpeg code : %d, ffmpeg msg : %s", result,error_string_buffer]
                                    code:JustDecoderErrorCodeCodecContextSetParam
                                userInfo:nil];
        avcodec_free_context(&codec_context);
        return error;
    }
    
    //4.设置时间线
    av_codec_set_pkt_timebase(codec_context, stream->time_base);
    //5.查找对应的解码器
    AVCodec * codec = avcodec_find_decoder(codec_context->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codec_context);
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@ codec not found decoder", domain]
                                    code:JustDecoderErrorCodeCodecFindDecoder
                                userInfo:nil];
        return error;
    }
    codec_context->codec_id = codec->id;
    
    AVDictionary * options = Just_FFMPEGNSDictionaryToAVDictionary(nil);
    if (!av_dict_get(options, "threads", NULL, 0)) {
        av_dict_set(&options, "threads", "auto", 0);
    }
    if (codec_context->codec_type == AVMEDIA_TYPE_VIDEO || codec_context->codec_type == AVMEDIA_TYPE_AUDIO) {
        av_dict_set(&options, "refcounted_frames", "1", 0);
    }
    //6.打开解码器
    result = avcodec_open2(codec_context, codec, &options);
    NSLog(@"tsytsytsy = 解码器打开成功");
    if (result < 0)
    {
        char * error_string_buffer = malloc(256);
        av_strerror(result, error_string_buffer, 256);
        error = [NSError errorWithDomain:[NSString stringWithFormat:@"ffmpeg code : %d, ffmpeg msg : %s", result,error_string_buffer]
                                    code:JustDecoderErrorCodeCodecOpen2
                                userInfo:nil];
        avcodec_free_context(&codec_context);
        return error;
    }
    
    * codecContext = codec_context;
    return error;
}

#pragma mark - seek

- (BOOL)seekEnable
{
    if (!self->_format_context) return NO;
    BOOL ioSeekAble = YES;
    if (self->_format_context->pb) {
        ioSeekAble = self->_format_context->pb->seekable;
    }
    if (ioSeekAble && self.duration > 0) {
        return YES;
    }
    return NO;
}

- (void)seekWithTimebase:(NSTimeInterval)time
{
    int64_t ts = time * AV_TIME_BASE;
    av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
}

- (void)seekWithVideo:(NSTimeInterval)time
{
    if (self.videoEnable)
    {
        int64_t ts = time * 1000.0 / self.videoTimebase;
        av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
    }
    else
    {
        [self seekWithTimebase:time];
    }
}

- (void)seekWithAudio:(NSTimeInterval)time
{
    if (self.audioTimebase)
    {
        int64_t ts = time * 1000 / self.audioTimebase;
        av_seek_frame(self->_format_context, -1, ts, AVSEEK_FLAG_BACKWARD);
    }
    else
    {
        [self seekWithTimebase:time];
    }
}

#pragma mark - tools

- (int)readFrame:(AVPacket *)packet
{
    return av_read_frame(self->_format_context, packet);
}

- (BOOL)containAudioTrack:(int)audioTrackIndex
{
    for (JustTrack * obj in self.audioTracks) {
        if (obj.index == audioTrackIndex) {
            return YES;
        }
    }
    return NO;
}

- (NSError * )selectAudioTrackIndex:(int)audioTrackIndex
{
    if (audioTrackIndex == self.audioTrack.index) return nil;
    if (![self containAudioTrack:audioTrackIndex]) return nil;
    
    AVCodecContext * codec_context;
    //获取解码器
    NSError * error = [self openStreamWithTrackIndex:audioTrackIndex codecContext:&codec_context domain:@"audio select"];
    if (!error)
    {
        if (_audio_codec_context)
        {
            avcodec_close(_audio_codec_context);
            _audio_codec_context = NULL;
        }
        for (JustTrack * obj in self.audioTracks)
        {
            if (obj.index == audioTrackIndex)
            {
                self.audioTrack = obj;
            }
        }
        self.audioEnable = YES;
        self.audioTimebase = Just_FFMPEGStreamGetTimebase(_format_context->streams[audioTrackIndex], 0.000025);
        self->_audio_codec_context = codec_context;
    }
    else
    {
        NSLog(@"select audio track error : %@", error);
    }
    return error;
}

- (NSTimeInterval)duration
{
    if (!self->_format_context) return 0;
    int64_t duration = self->_format_context->duration;
    if (duration < 0) {
        return 0;
    }
    return (NSTimeInterval)duration / AV_TIME_BASE;
}

- (NSTimeInterval)bitrate
{
    if (!self->_format_context) return 0;
    return (self->_format_context->bit_rate / 1000.0f);
}

- (NSString *)contentURLString
{
    if ([self.contentURL isFileURL])
    {
        return [self.contentURL path];
    }
    else
    {
        return [self.contentURL absoluteString];
    }
}

- (JustVideoFrameRotateType)videoFrameRotateType
{
    int rotate = [[self.videoTrack.metadata.metadata objectForKey:@"rotate"] intValue];
    if (rotate == 90) {
        return JustVideoFrameRotateType90;
    } else if (rotate == 180) {
        return JustVideoFrameRotateType180;
    } else if (rotate == 270) {
        return JustVideoFrameRotateType270;
    }
    return JustVideoFrameRotateType0;
}












@end
