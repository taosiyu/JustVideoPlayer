//
//  JustGLKFrame.h
//  JustPlayer
//
//  Created by Assassin on 2019/2/19.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustVideoFrame.h"

typedef NS_ENUM(NSUInteger, JustGLFrameType) {
    JustGLFrameTypeNV12,
    JustGLFrameTypeYUV420,
};

@interface JustGLKFrame : NSObject

+ (instancetype)frame;

@property (nonatomic, assign, readonly) JustGLFrameType type;

@property (nonatomic, assign, readonly) BOOL hasData;
@property (nonatomic, assign, readonly) BOOL hasUpate;
@property (nonatomic, assign, readonly) BOOL hasUpdateRotateType;

- (void)didDraw;
- (void)didUpdateRotateType;
- (void)flush;

- (void)updateWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVPixelBufferRef)pixelBufferForNV12;

- (void)updateWithSGFFVideoFrame:(JustVideoFrame *)videoFrame;
- (JustYUVVideoFrame *)pixelBufferForYUV420;

@property (nonatomic, assign) JustVideoFrameRotateType rotateType;


- (NSTimeInterval)currentPosition;
- (NSTimeInterval)currentDuration;

- (JustImage *)imageFromVideoFrame;

@end
