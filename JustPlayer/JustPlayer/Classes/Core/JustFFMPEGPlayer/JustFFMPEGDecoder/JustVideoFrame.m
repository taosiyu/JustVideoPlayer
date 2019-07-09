//
//  JustVideoFrame.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/8.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustVideoFrame.h"
#import "JustTools.h"

@implementation JustVideoFrame

- (JustFrameType)type
{
    return JustFrameTypeVideo;
}

@end


@interface JustYUVVideoFrame ()
{
    enum AVPixelFormat _pixelFormat;
    
    size_t _yuv_pixels_buffer_size[3];
    int _yuv_lenghts[3];
    int _yuv_linesize[3]; //对于视频，每一帧图象一行的字节大小。未必等于图像的宽，一般大于图像的宽
}

@property (nonatomic, strong) NSLock * lock;

@end

@implementation JustYUVVideoFrame

- (JustFrameType)type
{
    return JustFrameTypeAVYUVVideo;
}


+ (instancetype)videoFrame
{
    return [[self alloc] init];
}

#pragma mark - init

- (instancetype)init
{
    if (self = [super init]) {
        _yuv_lenghts[0] = 0;
        _yuv_lenghts[1] = 0;
        _yuv_lenghts[2] = 0;
        _yuv_pixels_buffer_size[0] = 0;
        _yuv_pixels_buffer_size[1] = 0;
        _yuv_pixels_buffer_size[2] = 0;
        _yuv_linesize[0] = 0;
        _yuv_linesize[1] = 0;
        _yuv_linesize[2] = 0;
        _yuv_pixels[0] = NULL;
        _yuv_pixels[1] = NULL;
        _yuv_pixels[2] = NULL;
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark - dealloc

- (void)dealloc
{
    if (_yuv_pixels[0] != NULL && _yuv_pixels_buffer_size[0] > 0) {
        free(_yuv_pixels[0]);
    }
    if (_yuv_pixels[1] != NULL && _yuv_pixels_buffer_size[1] > 0) {
        free(_yuv_pixels[1]);
    }
    if (_yuv_pixels[2] != NULL && _yuv_pixels_buffer_size[2] > 0) {
        free(_yuv_pixels[2]);
    }
}


//设置数据
- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height
{
    //获取解码后数据类型
    _pixelFormat = frame->format;
    
    self->_width = width;
    self->_height = height;
    
    if (_pixelFormat == AV_PIX_FMT_YUV420P)
    {
        //如果是yuv420p的
        int linesize_y = frame->linesize[0];
        int linesize_u = frame->linesize[1];
        int linesize_v = frame->linesize[2];
    
        _yuv_linesize[0] = linesize_y;
        _yuv_linesize[1] = linesize_u;
        _yuv_linesize[2] = linesize_v;
        
        //重用时，获取原来的数据
        UInt8 * buffer_y = _yuv_pixels[0];
        UInt8 * buffer_u = _yuv_pixels[1];
        UInt8 * buffer_v = _yuv_pixels[2];
        
        //重用时获取原来的数据打大小
        size_t buffer_size_y = _yuv_pixels_buffer_size[0];
        size_t buffer_size_u = _yuv_pixels_buffer_size[1];
        size_t buffer_size_v = _yuv_pixels_buffer_size[2];
        
        //Y的数据的长度=视频的原始宽(pCodecCtx->width) × 视频的原始高度(pCodecCtx->height)
        //u的数据的长度 = v = y/4
        int need_size_y = Just_FFMPEGYUVNeedSize(linesize_y, width, height, 1);
        _yuv_lenghts[0] = need_size_y;
        if (buffer_size_y < need_size_y) {
            if (buffer_size_y > 0 && buffer_y != NULL) {
                free(buffer_y);
            }
            //当需要的size大于原来开辟的空间大小时要重新开辟空间
            _yuv_pixels_buffer_size[0] = need_size_y;
            _yuv_pixels[0] = malloc(need_size_y);
        }
        
        int need_size_u = Just_FFMPEGYUVNeedSize(linesize_u, width / 2, height / 2, 1);
        _yuv_lenghts[1] = need_size_u;
        if (buffer_size_u < need_size_u) {
            if (buffer_size_u > 0 && buffer_u != NULL) {
                free(buffer_u);
            }
            _yuv_pixels_buffer_size[1] = need_size_u;
            _yuv_pixels[1] = malloc(need_size_u);
        }
        
        int need_size_v = Just_FFMPEGYUVNeedSize(linesize_v, width / 2, height / 2, 1);
        _yuv_lenghts[2] = need_size_v;
        if (buffer_size_v < need_size_v) {
            if (buffer_size_v > 0 && buffer_v != NULL) {
                free(buffer_v);
            }
            _yuv_pixels_buffer_size[2] = need_size_v;
            _yuv_pixels[2] = malloc(need_size_v);
        }
        
        Just_FFMPEGYUVFilter(frame->data[0],
                           linesize_y,
                           width,
                           height,
                           _yuv_pixels[0],
                           _yuv_pixels_buffer_size[0],
                           1);
        Just_FFMPEGYUVFilter(frame->data[1],
                           linesize_u,
                           width / 2,
                           height / 2,
                           _yuv_pixels[1],
                           _yuv_pixels_buffer_size[1],
                           1);
        Just_FFMPEGYUVFilter(frame->data[2],
                           linesize_v,
                           width / 2,
                           height / 2,
                           _yuv_pixels[2],
                           _yuv_pixels_buffer_size[2],
                           1);
    
    }

}

- (void)stopPlaying
{
    [self.lock lock];
    [super stopPlaying];
    [self.lock unlock];
}

- (JustImage *)image
{
    [self.lock lock];
    JustImage * image = Just_FFMPEGYUVConvertToImage(_yuv_pixels, _yuv_linesize, self.width, self.height, _pixelFormat);
    [self.lock unlock];
    return image;
}

- (int)size
{
    return (int)(_yuv_lenghts[0] + _yuv_lenghts[1] + _yuv_lenghts[2]);
}

@end


@implementation JustFFCVYUVVideoFrame

- (JustFrameType)type
{
    return JustFFFrameTypeCVYUVVideo;
}

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self = [super init]) {
        self->_pixelBuffer = pixelBuffer;
    }
    return self;
}

- (void)dealloc
{
    if (self->_pixelBuffer) {
        CVPixelBufferRelease(self->_pixelBuffer);
        self->_pixelBuffer = NULL;
    }
}

@end






