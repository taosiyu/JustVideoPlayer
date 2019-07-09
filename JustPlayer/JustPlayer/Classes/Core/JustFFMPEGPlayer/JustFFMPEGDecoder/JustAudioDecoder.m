//
//  JustAudioDecoder.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustAudioDecoder.h"
#import "JustFramePool.h"
#import "JustFrameQueue.h"
#import <libswscale/swscale.h>
#import <libavutil/frame.h>
#import <libswresample/swresample.h>

#import <Accelerate/Accelerate.h>

@interface JustAudioDecoder ()
{
    AVCodecContext * _codec_context; //音频解码
    AVFrame * _temp_frame;           //临时解码文件
    SwrContext * _audio_swr_context;
    
    NSTimeInterval _timebase;
    Float64 _samplingRate;
    UInt32 _channelCount;
    
    
    void * _audio_swr_buffer;
    int _audio_swr_buffer_size;
}

@property (nonatomic, strong) JustFramePool  * framePool;
@property (nonatomic, strong) JustFrameQueue * frameQueue;

@end

@implementation JustAudioDecoder

#pragma mark - init

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context timebase:(NSTimeInterval)timebase delegate:(id<JustAudioDecoderDelegate>)delegate
{
    return [[self alloc] initWithCodecContext:codec_context timebase:timebase delegate:delegate];
}

- (instancetype)initWithCodecContext:(AVCodecContext *)codec_context timebase:(NSTimeInterval)timebase delegate:(id<JustAudioDecoderDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
        self->_codec_context = codec_context;
        self->_temp_frame = av_frame_alloc();
        self->_timebase = timebase;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frameQueue = [JustFrameQueue frameQueue];
    self.framePool = [JustFramePool audioPool];
    [self setupSwsContext];
}

- (void)setupSwsContext
{
    [self reloadAudioOuputInfo];
    
    //设置音频输出格式 统一音频采样格式与采样率
    _audio_swr_context = swr_alloc_set_opts(NULL, av_get_default_channel_layout(_channelCount), AV_SAMPLE_FMT_S16, _samplingRate, av_get_default_channel_layout(_codec_context->channels), _codec_context->sample_fmt, _codec_context->sample_rate, 0, NULL);
    
    int result = swr_init(_audio_swr_context);
    if (result < 0 || !_audio_swr_context) {
        if (_audio_swr_context) {
            swr_free(&_audio_swr_context);
        }
    }
}

#pragma mark - dealloc

- (void)dealloc
{
    if (_audio_swr_buffer) {
        free(_audio_swr_buffer);
        _audio_swr_buffer = NULL;
        _audio_swr_buffer_size = 0;
    }
    if (_audio_swr_context) {
        swr_free(&_audio_swr_context);
        _audio_swr_context = NULL;
    }
    if (_temp_frame) {
        av_free(_temp_frame);
        _temp_frame = NULL;
    }
    NSLog(@"JustAudioDecoder release");
}

#pragma mark - private

- (void)reloadAudioOuputInfo
{
    if ([self.delegate respondsToSelector:@selector(audioDecoder:samplingRate:)]) {
        [self.delegate audioDecoder:self samplingRate:&self->_samplingRate];
    }
    if ([self.delegate respondsToSelector:@selector(audioDecoder:channelCount:)]) {
        [self.delegate audioDecoder:self channelCount:&self->_channelCount];
    }
}

- (int)putPacket:(AVPacket)packet
{
    if (packet.data == NULL) return 0;
    
    int result = avcodec_send_packet(_codec_context, &packet);
    if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
        return -1;
    }
    
    while (result >= 0) {
        result = avcodec_receive_frame(_codec_context, _temp_frame);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return -1;
            }
            break;
        }
        @autoreleasepool
        {
            JustAudioFrame * frame = [self decode:packet.size];
            if (frame) {
                [self.frameQueue putFrame:frame];
            }
        }
    }
    av_packet_unref(&packet);
    return 0;
}

- (JustAudioFrame *)decode:(int)packetSize
{
    if (!_temp_frame->data[0]) return nil;
    
    [self reloadAudioOuputInfo];
    
    int numberOfFrames;
    void * audioDataBuffer;
    
    if (_audio_swr_context) {
        const int ratio = MAX(1, _samplingRate / _codec_context->sample_rate) * MAX(1, _channelCount / _codec_context->channels) * 2;
        const int buffer_size = av_samples_get_buffer_size(NULL, _channelCount, _temp_frame->nb_samples * ratio, AV_SAMPLE_FMT_S16, 1);
        
        if (!_audio_swr_buffer || _audio_swr_buffer_size < buffer_size) {
            _audio_swr_buffer_size = buffer_size;
            _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size);
        }
        
        Byte * outyput_buffer[2] = {_audio_swr_buffer, 0};
        //转换格式
        numberOfFrames = swr_convert(_audio_swr_context, outyput_buffer, _temp_frame->nb_samples * ratio, (const uint8_t **)_temp_frame->data, _temp_frame->nb_samples);
        if (numberOfFrames < 0) {
            NSLog(@"audio codec error : %i", numberOfFrames);
            return nil;
        }
        audioDataBuffer = _audio_swr_buffer;
    } else {
        if (_codec_context->sample_fmt != AV_SAMPLE_FMT_S16) {
            NSLog(@"audio format error");
            return nil;
        }
        audioDataBuffer = _temp_frame->data[0];
        numberOfFrames = _temp_frame->nb_samples;
    }
    
    JustAudioFrame * audioFrame = [self.framePool getUnuseFrame];
    audioFrame.packetSize = packetSize;
    audioFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * _timebase;
    audioFrame.duration = av_frame_get_pkt_duration(_temp_frame) * _timebase;
    
    if (audioFrame.duration == 0) {
        audioFrame.duration = audioFrame->length / (sizeof(float) * _channelCount * _samplingRate);
    }
    
    const NSUInteger numberOfElements = numberOfFrames * self->_channelCount;
    [audioFrame setSamplesLength:numberOfElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioDataBuffer, 1, audioFrame->samples, 1, numberOfElements);
    vDSP_vsmul(audioFrame->samples, 1, &scale, audioFrame->samples, 1, numberOfElements);
//    vDSP_vflt16将非交错的16位带符号整数（non-interleaved 16-bit signed integers）转换成单精度浮点数。为什么是16位带符号整数？原因是，这取决于AudioStreamBasicDescription.mBitsPerChannel字段的值。当AudioStreamBasicDescription.mBitsPerChannel为16时，则调用vDSP_vflt16。当AudioStreamBasicDescription.mBitsPerChannel为32时，则调用vDSP_vflt32。

    
    return audioFrame;
}

#pragma mark - public

- (int)size
{
    return self.frameQueue.packetSize;
}

- (BOOL)empty
{
    return self.frameQueue.count <= 0;
}

- (NSTimeInterval)duration
{
    return self.frameQueue.duration;
}

- (void)flush
{
    [self.frameQueue flush];
    [self.framePool flush];
    if (_codec_context) {
        avcodec_flush_buffers(_codec_context);
    }
}

- (JustAudioFrame *)getFrameSync
{
    return [self.frameQueue getFrameSync];
}

- (void)destroy
{
    [self.frameQueue destroy];
    [self.framePool flush];
}

@end




















