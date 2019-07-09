//
//  JustYUV420Texture.m
//  JustPlayer
//
//  Created by Assassin on 2019/2/19.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustYUV420Texture.h"
#import <OpenGLES/ES3/gl.h>

@implementation JustYUV420Texture

static GLuint gl_texture_ids[3];

- (instancetype)init
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            glGenTextures(3, gl_texture_ids);
        });
    }
    return self;
}

- (BOOL)updateTextureWithGLFrame:(JustGLKFrame *)glFrame aspect:(CGFloat *)aspect
{
    
    JustYUVVideoFrame * videoFrame = [glFrame pixelBufferForYUV420];
    
    if (!videoFrame) {
        return NO;
    }
    
    const int frameWidth = videoFrame.width;
    const int frameHeight = videoFrame.height;
    * aspect = (frameWidth * 1.0) / (frameHeight * 1.0);
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    const int widths[3]  = {
        frameWidth,
        frameWidth / 2,
        frameWidth / 2
    };
    const int heights[3] = {
        frameHeight,
        frameHeight / 2,
        frameHeight / 2
    };
    
    for (GLenum channel = 0; channel < 3; channel++)
    {
        glActiveTexture(GL_TEXTURE0 + channel);
        glBindTexture(GL_TEXTURE_2D, gl_texture_ids[channel]);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE, //GL_LUMINANCE 表示按照亮度
                     widths[channel],
                     heights[channel],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     videoFrame->_yuv_pixels[channel]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    return YES;

}

@end
