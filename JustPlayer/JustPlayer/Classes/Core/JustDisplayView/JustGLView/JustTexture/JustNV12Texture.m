//
//  JustNV12Texture.m
//  JustPlayer
//
//  Created by Assassin on 2019/5/8.
//  Copyright © 2019 PeachRain. All rights reserved.
//

#import "JustNV12Texture.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "JustFormatContext.h"

@interface JustNV12Texture()

@property (nonatomic, strong) EAGLContext * context;

@property (nonatomic, assign) CVOpenGLESTextureRef lumaTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef chromaTexture;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef videoTextureCache;

@property (nonatomic, assign) CGFloat textureAspect;
@property (nonatomic, assign) BOOL didBindTexture;

@end

@implementation JustNV12Texture

- (instancetype)initWithContext:(EAGLContext *)context
{
    if (self = [super init]) {
        self.context = context;
        [self setupVideoCache];
    }
    return self;
}

- (void)setupVideoCache
{
    if (!self.videoTextureCache) {
        CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (result != noErr) {
            NSLog(@"create CVOpenGLESTextureCacheCreate failure %d", result);
            return;
        }
    }
}

- (BOOL)updateTextureWithGLFrame:(JustGLKFrame *)glFrame aspect:(CGFloat *)aspect
{
    CVPixelBufferRef pixelBuffer = [glFrame pixelBufferForNV12];
    //获取buffer内的图形数据与openGL纹理进行绑定
    if (pixelBuffer == nil) {
        if (self.lumaTexture && self.chromaTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
            * aspect = self.textureAspect;
            return YES;
        } else {
            return NO;
        }
    }
    
    if (!self.videoTextureCache) {
        NSLog(@"no video texture cache");
        return NO;
    }
    
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    self.textureAspect = (textureWidth * 1.0) / (textureHeight * 1.0);
    * aspect = self.textureAspect;
    
    [self cleanTextures];
    
    CVReturn result;
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
//    Y分量独占一个PBO和一个Texture，纹理的格式为GL_RED，大小是解码出来的宽width*高height
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RED_EXT,
                                                          textureWidth,
                                                          textureHeight,
                                                          GL_RED_EXT,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &_lumaTexture);
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        //上述为一些图形显示设置（如边缘过渡类型等）
    } else {
        NSLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 1 %d", result);
    }
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
//    UV分量再写一个PBO和Texture，为了一次获取一对UV分量，纹理的格式选择GL_RG，这是个双通道所以纹理的宽就变成了width/2
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RG_EXT,
                                                          textureWidth/2,
                                                          textureHeight/2,
                                                          GL_RG_EXT,
                                                          GL_UNSIGNED_BYTE,
                                                          1,
                                                          &_chromaTexture);
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    } else {
        NSLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 2 %d", result);
    }
    
    self.didBindTexture = YES;
    return YES;
}

- (void)clearVideoCache
{
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        self.videoTextureCache = nil;
    }
}

- (void)cleanTextures
{
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    self.textureAspect = 16.0 / 9.0;
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc
{
    [self clearVideoCache];
    [self cleanTextures];
    NSLog(@"SGAVGLTexture release");
}



@end
