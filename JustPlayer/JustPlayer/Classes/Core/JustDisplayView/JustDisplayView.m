//
//  JustDisplayView.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustDisplayView.h"
#import "JustGLKViewController.h"

@interface JustDisplayView ()

@property (nonatomic, weak) JustPlayerManager * playerConfigure;

@property (nonatomic, strong) AVPlayerLayer * avplayerLayer;            //avplayer 用
@property (nonatomic,strong) JustGLKViewController * glViewController;   //FFMPEG  用

@end

@implementation JustDisplayView

#pragma mark - init

+ (instancetype)displayViewWithPlayerConfigure:(JustPlayerManager *)playerConfigure
{
    return [[self alloc] initWithPlayerConfigure:playerConfigure];
}

- (instancetype)initWithPlayerConfigure:(JustPlayerManager *)playerConfigure
{
    if (self = [super initWithFrame:CGRectZero])
    {
        self.playerConfigure = playerConfigure;
        [self viewBaseSetting];
        [self setupEventHandler];
    }
    return self;
}

- (void)viewBaseSetting
{
    self.backgroundColor = [UIColor blackColor];
}

- (void)playerOutputTypeAVPlayer
{
    self->_playerOutputType = JustDisplayPlayerOutputTypeAVPlayer;
}

- (void)playerOutputTypeFF
{
    self->_playerOutputType = JustDisplayPlayerOutputTypeFFMPEG;
}

- (void)rendererTypeEmpty
{
    if (self.rendererType != JustDisplayRendererTypeEmpty) {
        self->_rendererType = JustDisplayRendererTypeEmpty;
        [self reloadView];
    }
}

- (void)rendererTypeAVPlayerLayer
{
    if (self.rendererType != JustDisplayRendererTypeAVPlayerLayer) {
        self->_rendererType = JustDisplayRendererTypeAVPlayerLayer;
        [self reloadView];
    }
}

- (void)rendererTypeOpenGL
{
    if (self.rendererType != JustDisplayRendererTypeOpenGL) {
        self->_rendererType = JustDisplayRendererTypeOpenGL;
        [self reloadView];
    }
}

#pragma mark - dealloc

-(void)dealloc
{
    [self cleanView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cleanView
{
    if (self.avplayerLayer) {
        [self.avplayerLayer removeFromSuperlayer];
        self.avplayerLayer.player = nil;
        self.avplayerLayer = nil;
    }
    if (self.glViewController) {
        GLKView * glView = (GLKView*)self.glViewController.view;
        [glView removeFromSuperview];
        self.glViewController = nil;
    }
//    self.avplayerLayerToken = NO;
//    [self.fingerRotation clean];
}

#pragma mark - reloadView

- (void)reloadView
{
    [self cleanView];
    switch (self.rendererType) {
        case JustDisplayRendererTypeEmpty:
            break;
        case JustDisplayRendererTypeAVPlayerLayer:
        {
            self.avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
            [self reloadPlayerConfig];
//            self.avplayerLayerToken = NO;
            [self.layer insertSublayer:self.avplayerLayer atIndex:0];
            [self reloadGravityMode];
        }
            break;
        case JustDisplayRendererTypeOpenGL:
        {
            self.glViewController = [JustGLKViewController viewControllerWithDisplayView:self];
            dispatch_async(dispatch_get_main_queue(), ^{
                GLKView * glView = (GLKView*)self.glViewController.view;
                [self insertSubview:glView atIndex:0];
            });
        }
            break;
    }
    //设置显示layer的尺寸frame
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDisplayViewLayout:self.bounds];
    });
}

- (void)reloadPlayerConfig
{
    if (self.avplayerLayer && self.playerOutputType == JustDisplayPlayerOutputTypeAVPlayer) {
        if ([self.playerOutputAV playerOutputGetAVPlayer] && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            self.avplayerLayer.player = [self.playerOutputAV playerOutputGetAVPlayer];
        } else {
            self.avplayerLayer.player = nil;
        }
    }
}

- (void)reloadGravityMode
{
    if (self.avplayerLayer) {
        switch (self.playerConfigure.viewGravityMode) {
            case JustGravityModeResize:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResize;
                break;
            case JustGravityModeResizeAspect:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                break;
            case JustGravityModeResizeAspectFill:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                break;
        }
    }
}

- (void)reloadVideoFrameForGLFrame:(JustGLKFrame *)glFrame
{
    switch (self.playerOutputType) {
        case JustDisplayPlayerOutputTypeEmpty:
            break;
        case JustDisplayPlayerOutputTypeAVPlayer:
        {
            CVPixelBufferRef pixelBuffer = [self.playerOutputAV playerOutputGetPixelBufferAtCurrentTime];
            if (pixelBuffer) {
                [glFrame updateWithCVPixelBuffer:pixelBuffer];
            }
        }
            break;
        case JustDisplayPlayerOutputTypeFFMPEG:
        {
            JustVideoFrame * videoFrame = [self.playerOutputFF playerOutputGetVideoFrameWithCurrentPostion:glFrame.currentPosition
                                                                                           currentDuration:glFrame.currentDuration];
            NSLog(@"tsy position = %lf current = %lf",glFrame.currentPosition,glFrame.currentDuration);
            if (videoFrame) {
                [glFrame updateWithSGFFVideoFrame:videoFrame];
                glFrame.rotateType = videoFrame.rotateType;
            }
        }
            break;
    }
    
}

#pragma mark - update view

- (void)updateDisplayViewLayout:(CGRect)frame
{
    if (self.avplayerLayer) {
        self.avplayerLayer.frame = frame;
        [self.avplayerLayer removeAllAnimations];
    }
    if (self.glViewController) {
        [self.glViewController reloadViewport];
    }
}


#pragma mark - Event Handler

- (void)setupEventHandler
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iOS_applicationDidEnterBackgroundAction:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iOS_applicationWillEnterForegroundAction:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    UITapGestureRecognizer * tapGestureRecigbuzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iOS_tapGestureRecigbuzerAction:)];
    [self addGestureRecognizer:tapGestureRecigbuzer];
}

#pragma mark - public functions

- (JustImage *)snapshot
{
    switch (self.rendererType) {
        case JustDisplayRendererTypeEmpty:
            return nil;
        case JustDisplayRendererTypeAVPlayerLayer:
            return [self.playerOutputAV playerOutputGetSnapshotAtCurrentTime];
        case JustDisplayRendererTypeOpenGL:
            return [self.glViewController snapshot];
    }
}

- (void)playerOutputTypeEmpty
{
    self->_playerOutputType = JustDisplayPlayerOutputTypeEmpty;
}

#pragma mark - notification

- (void)iOS_applicationDidEnterBackgroundAction:(NSNotification *)notification
{
    if (_avplayerLayer) {
        _avplayerLayer.player = nil;
    }
}

- (void)iOS_applicationWillEnterForegroundAction:(NSNotification *)notification
{
    if (_avplayerLayer) {
        _avplayerLayer.player = [self.playerOutputAV playerOutputGetAVPlayer];
    }
}

- (void)iOS_tapGestureRecigbuzerAction:(NSNotification *)notification {
    if (self.playerConfigure.viewTapAction) {
        self.playerConfigure.viewTapAction(self.playerConfigure, self.playerConfigure.view);
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
}


@end
