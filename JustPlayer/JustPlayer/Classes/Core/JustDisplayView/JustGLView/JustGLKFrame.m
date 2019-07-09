//
//  JustGLKFrame.m
//  JustPlayer
//
//  Created by Assassin on 2019/2/19.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustGLKFrame.h"

@interface JustGLKFrame ()

//硬件解码用
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

@property (nonatomic, strong) JustVideoFrame * videoFrame;

@end

@implementation JustGLKFrame

+ (instancetype)frame
{
    return [[self alloc] init];
}

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
{
    [self flush];
    NSLog(@"tsy测试代码 N12");
    self->_type = JustGLFrameTypeNV12;
    self.pixelBuffer = pixelBuffer;
    
    self->_hasData = YES;
    self->_hasUpate = YES;
}
- (CVPixelBufferRef)pixelBufferForNV12
{
    if (self.pixelBuffer) {
        return self.pixelBuffer;
    } else {
        return [(JustFFCVYUVVideoFrame *)self.videoFrame pixelBuffer];
    }
    return nil;
}

- (void)updateWithSGFFVideoFrame:(JustVideoFrame *)videoFrame;
{
    [self flush];
    NSLog(@"tsy测试代码 YUV420");
    self.videoFrame = videoFrame;
    if ([videoFrame isKindOfClass:[JustFFCVYUVVideoFrame class]]) {
        self->_type = JustGLFrameTypeNV12;
    } else {
        self->_type = JustGLFrameTypeYUV420;
    }
    [self.videoFrame startPlaying];
    
    self->_hasData = YES;
    self->_hasUpate = YES;
}

- (JustYUVVideoFrame *)pixelBufferForYUV420
{
    return (JustYUVVideoFrame *)self.videoFrame;
}

- (void)setRotateType:(JustVideoFrameRotateType)rotateType
{
    if (_rotateType != rotateType) {
        _rotateType = rotateType;
        self->_hasUpdateRotateType = YES;
    }
}

- (NSTimeInterval)currentPosition
{
    if (self.videoFrame) {
        return self.videoFrame.position;
    }
    return -1;
}

- (NSTimeInterval)currentDuration
{
    if (self.videoFrame) {
        return self.videoFrame.duration;
    }
    return -1;
}

- (JustImage *)imageFromVideoFrame
{
    if ([self.videoFrame isKindOfClass:[JustYUVVideoFrame class]]) {
        JustYUVVideoFrame * frame = (JustYUVVideoFrame *)self.videoFrame;
        JustImage * image = frame.image;
        if (image) return image;
    }else if ([self.videoFrame isKindOfClass:[JustFFCVYUVVideoFrame class]]) {
        JustFFCVYUVVideoFrame * frame = (JustFFCVYUVVideoFrame *)self.videoFrame;
        if (frame.pixelBuffer) {
            JustImage * image = JustGetImageWithCVPixelBuffer(frame.pixelBuffer);
            if (image) return image;
        }
    }
    return nil;
}

#pragma mark - public

- (void)didDraw
{
    self->_hasUpate = NO;
}

- (void)didUpdateRotateType
{
    self->_hasUpdateRotateType = NO;
}

- (void)flush
{
    self->_hasData = NO;
    self->_hasUpate = NO;
    self->_hasUpdateRotateType = NO;
    if (self.pixelBuffer) {
        CVPixelBufferRelease(self.pixelBuffer);
        self.pixelBuffer = NULL;
    }
    if (self.videoFrame) {
        [self.videoFrame stopPlaying];
        self.videoFrame = nil;
    }
}

- (void)dealloc
{
    [self flush];
}

@end
