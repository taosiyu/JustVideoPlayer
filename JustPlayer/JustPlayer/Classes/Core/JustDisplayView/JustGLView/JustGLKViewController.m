//
//  JustGLKViewController.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/18.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustGLKViewController.h"
#import "JustGLKFrame.h"
#import "JustYUV420Texture.h"
#import "JustYUV420Shader.h"
#import "JustNV12Texture.h"
#import "JustNV12Shader.h"
#import "JustNormalModel.h"
#import "JustTexture.h"

@interface JustGLKViewController ()

@property (nonatomic, strong) NSLock * openGLLock;
@property (nonatomic, assign) CGFloat aspect;
@property (nonatomic, assign) CGRect viewport;
@property (nonatomic, assign) BOOL clearToken;
@property (nonatomic, assign) BOOL drawToken;

@property (nonatomic, strong) JustGLKFrame * currentFrame;

@property (nonatomic, strong) JustNormalModel * normalModel;
@property (nonatomic, strong) JustYUV420Texture * textureYUV420;
@property (nonatomic, strong) JustYUV420Shader * programYUV420;

@property (nonatomic, strong) JustNV12Texture * textureNV12;
@property (nonatomic, strong) JustNV12Shader * programNV12;

@end

@implementation JustGLKViewController

#pragma mark - dealloc

- (void)dealloc
{
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - screen

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (size.width > size.height) {
        //横屏设置
        
    }else{
        //竖屏设置
    }
}

#pragma mark - init

+ (instancetype)viewControllerWithDisplayView:(JustDisplayView *)displayView
{
    return [[self alloc] initWithDisplayView:displayView];
}

- (instancetype)initWithDisplayView:(JustDisplayView *)displayView
{
    if (self = [super init]) {
        self->_displayView = displayView;
    }
    return self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat scale = [UIScreen mainScreen].scale;
    GLKView *glkView = (GLKView *)self.view;
//    self.distorionRenderer.viewportSize = CGSizeMake(CGRectGetWidth(glView.bounds) * scale, CGRectGetHeight(glView.bounds) * scale);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupOpenGL];
}

- (void)setupOpenGL
{
    self.openGLLock = [[NSLock alloc] init];
    GLKView *glkView = (GLKView *)self.view;
    glkView.backgroundColor = [UIColor blackColor];
    
    //context init
    EAGLContext *glkContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    glkView.context = glkContext;
    [EAGLContext setCurrentContext:glkContext];
    //glkView setting
    glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    glkView.contentScaleFactor = [UIScreen mainScreen].scale;
    self.pauseOnWillResignActive = NO;
    self.resumeOnDidBecomeActive = YES;
    
    //base setting
    self.textureYUV420 = [[JustYUV420Texture alloc] init];
    self.programYUV420 = [JustYUV420Shader program];
    
    self.textureNV12 = [[JustNV12Texture alloc] init];
    self.programNV12 = [JustNV12Shader program];
    
    self.normalModel = [JustNormalModel model];
    
    self.currentFrame = [JustGLKFrame frame];
    self.aspect = 16.0 / 9.0;
    self.preferredFramesPerSecond = 35;
    
}

- (void)flushClearColor
{
    NSLog(@"flush .....");
    [self.openGLLock lock];
    self.clearToken = YES;
    self.drawToken = NO;
    [self.currentFrame flush];
    [self.textureYUV420 flush];
    [self.openGLLock unlock];
}

#pragma mark - public

- (JustImage *)snapshot
{
//    if (self.displayView.abstractPlayer.videoType == SGVideoTypeVR) {
//        SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
//        return SGPLFGLViewGetCurrentSnapshot(glView);
//    } else {
        JustImage * image = [self.currentFrame imageFromVideoFrame];
        if (image) {
            return image;
        }
//    }
    GLKView *glkView = (GLKView *)self.view;
    return glkView.snapshot;
}

#pragma mark - draw

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.openGLLock lock];
    EAGLContext * context = view.context;
    [EAGLContext setCurrentContext:context];
    
    if (self.clearToken) {
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        self.clearToken = NO;
    } else if ([self needDrawOpenGL]) {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            [self.openGLLock unlock];
            return;
        }
        GLKView * glView = (GLKView*)self.view;
        self.viewport = glView.bounds;
        [self drawOpenGL];
        [self.currentFrame didDraw];
        self.drawToken = YES;
    }
    
    
    [self.openGLLock unlock];
}

- (JustTexture *)chooseTexture
{
    switch (self.currentFrame.type) {
        case JustGLFrameTypeNV12:
            return self.textureNV12;
        case JustGLFrameTypeYUV420:
        return self.textureYUV420;
    }
}

- (JustShader *)chooseProgram
{
    switch (self.currentFrame.type) {
        case JustGLFrameTypeNV12:
            return self.programNV12;
        case JustGLFrameTypeYUV420:
            return self.programYUV420;
    }
}

- (JustGLModelTextureRotateType)chooseModelTextureRotateType
{
    switch (self.currentFrame.rotateType) {
        case JustVideoFrameRotateType0:
            return JustGLModelTextureRotateType0;
        case JustVideoFrameRotateType90:
            return JustGLModelTextureRotateType90;
        case JustVideoFrameRotateType180:
            return JustGLModelTextureRotateType180;
        case JustVideoFrameRotateType270:
            return JustGLModelTextureRotateType270;
    }
    return JustGLModelTextureRotateType0;
}

#pragma mark - private

- (void)setAspect:(CGFloat)aspect
{
    if (_aspect != aspect) {
        _aspect = aspect;
        [self reloadViewport];
    }
}

- (BOOL)needDrawOpenGL
{
    [self.displayView reloadVideoFrameForGLFrame:self.currentFrame];
    if (!self.currentFrame.hasData) {
        return NO;
    }
    if ( !self.currentFrame.hasUpate && self.drawToken) {
        return NO;
    }
    
    JustTexture * texture = [self chooseTexture];
    CGFloat aspect = 16.0 / 9.0;
    if (![texture updateTextureWithGLFrame:self.currentFrame aspect:&aspect]) {
        return NO;
    }
    
//    if (self.displayView.abstractPlayer.videoType == SGVideoTypeVR) {
//        self.aspect = 16.0 / 9.0;
//    } else {
        self.aspect = aspect;
//    }
    if (self.currentFrame.hasUpdateRotateType) {
        [self reloadViewport];
    }
    return YES;
}

- (void)drawOpenGL
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    JustVideoType videoType = self.displayView.playerConfigure.videoType;
//    JustDisplayModel displayMode = self.displayView.abstractPlayer.displayMode;
//
//#if SGPLATFORM_TARGET_OS_IPHONE
//    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
//        [self.distorionRenderer beforDrawFrame];
//    }
//#endif
    
    JustShader * program = [self chooseProgram];
    [program use];
    [program bindVariable];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGRect rect = CGRectMake(0, 0, self.viewport.size.width * scale, self.viewport.size.height * scale);
    switch (videoType) {
        case JustVideoTypeNormal:
        {
            [self.normalModel bindPositionLocation:program.position_location textureCoordLocation:program.texture_coord_location textureRotateType:[self chooseModelTextureRotateType]];
            glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
            [program updateMatrix:GLKMatrix4Identity];
            glDrawElements(GL_TRIANGLES, self.normalModel.index_count, GL_UNSIGNED_SHORT, 0);
        }
            break;
//        case SGVideoTypeVR:
//        {
//            [self.vrModel bindPositionLocation:program.position_location textureCoordLocation:program.texture_coord_location];
//            switch (displayMode) {
//                case SGDisplayModeNormal:
//                {
//                    GLKMatrix4 matrix;
//                    BOOL success = [self.vrMatrix singleMatrixWithSize:rect.size matrix:&matrix fingerRotation:self.displayView.fingerRotation];
//                    if (success) {
//                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
//                        [program updateMatrix:matrix];
//                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
//                    }
//                }
//                    break;
//                case SGDisplayModeBox:
//                {
//                    GLKMatrix4 leftMatrix;
//                    GLKMatrix4 rightMatrix;
//                    BOOL success = [self.vrMatrix doubleMatrixWithSize:rect.size leftMatrix:&leftMatrix rightMatrix:&rightMatrix];
//                    if (success) {
//                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
//                        [program updateMatrix:leftMatrix];
//                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
//
//                        glViewport(CGRectGetWidth(rect)/2 + rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
//                        [program updateMatrix:rightMatrix];
//                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
//                    }
//                }
//                    break;
//            }
//        }
//            break;
    }
    
//#if SGPLATFORM_TARGET_OS_IPHONE
//    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
//        SGPLFGLView * glView = SGPLFGLViewControllerGetGLView(self);
//        SGPLFGLViewBindFrameBuffer(glView);
//        [self.distorionRenderer afterDrawFrame];
//    }
//#endif
}

- (void)reloadViewport
{
    GLKView * glView = (GLKView*)self.view;
    CGRect superviewFrame = glView.superview.bounds;
    CGFloat superviewAspect = superviewFrame.size.width / superviewFrame.size.height;
    
    if (self.aspect <= 0) {
        glView.frame = superviewFrame;
        return;
    }
    
    CGFloat resultAspect = self.aspect;
    switch (self.currentFrame.rotateType) {
        case JustVideoFrameRotateType90:
        case JustVideoFrameRotateType270:
            resultAspect = 1 / self.aspect;
            break;
        case JustVideoFrameRotateType0:
        case JustVideoFrameRotateType180:
            break;
    }
    
    JustGravityMode gravityMode = self.displayView.playerConfigure.viewGravityMode;
    switch (gravityMode) {
        case JustGravityModeResize:
            glView.frame = superviewFrame;
            break;
        case JustGravityModeResizeAspect:
            if (superviewAspect < resultAspect) {
                CGFloat height = superviewFrame.size.width / resultAspect;
                glView.frame = CGRectMake(0, (superviewFrame.size.height - height) / 2, superviewFrame.size.width, height);
            } else if (superviewAspect > resultAspect) {
                CGFloat width = superviewFrame.size.height * resultAspect;
                glView.frame = CGRectMake((superviewFrame.size.width - width) / 2, 0, width, superviewFrame.size.height);
            } else {
                glView.frame = superviewFrame;
            }
            break;
        case JustGravityModeResizeAspectFill:
            if (superviewAspect < resultAspect) {
                CGFloat width = superviewFrame.size.height * resultAspect;
                glView.frame = CGRectMake(-(width - superviewFrame.size.width) / 2, 0, width, superviewFrame.size.height);
            } else if (superviewAspect > resultAspect) {
                CGFloat height = superviewFrame.size.width / resultAspect;
                glView.frame = CGRectMake(0, -(height - superviewFrame.size.height) / 2, superviewFrame.size.width, height);
            } else {
                glView.frame = superviewFrame;
            }
            break;
        default:
            glView.frame = superviewFrame;
            break;
    }
    self.drawToken = NO;
    [self.currentFrame didUpdateRotateType];
}



@end
