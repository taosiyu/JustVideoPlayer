//
//  JustVideoFrame.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/8.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustFrame.h"
#import <libavutil/frame.h>
#import "JustImage.h"

typedef NS_ENUM(NSUInteger, JustVideoFrameRotateType) {
    JustVideoFrameRotateType0,
    JustVideoFrameRotateType90,
    JustVideoFrameRotateType180,
    JustVideoFrameRotateType270,
};

@interface JustVideoFrame : JustFrame

@property (nonatomic, assign) JustVideoFrameRotateType rotateType;

@end


// FFmpeg AVFrame YUV frame
@interface JustYUVVideoFrame : JustVideoFrame
{
@public
    UInt8 * _yuv_pixels[3]; //存储的数据
}

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

+ (instancetype)videoFrame;
- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height;

- (JustImage *)image;

@end

// CoreVideo YUV frame
@interface JustFFCVYUVVideoFrame : JustVideoFrame

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
