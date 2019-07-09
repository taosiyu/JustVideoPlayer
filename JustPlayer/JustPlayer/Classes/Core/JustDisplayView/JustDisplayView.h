//
//  JustDisplayView.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JustPlayerConfigure.h"
#import "JustAVPlayer.h"
#import "JustImage.h"
#import "JustGLKFrame.h"
#import "JustFFPlayer.h"

typedef NS_ENUM(NSUInteger, JustDisplayRendererType) {
    JustDisplayRendererTypeEmpty,
    JustDisplayRendererTypeAVPlayerLayer,
    JustDisplayRendererTypeOpenGL,
};

typedef NS_ENUM(NSUInteger, JustDisplayPlayerOutputType) {
    JustDisplayPlayerOutputTypeEmpty,
    JustDisplayPlayerOutputTypeFFMPEG,
    JustDisplayPlayerOutputTypeAVPlayer,
};

@interface JustDisplayView : UIView

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;


@property (nonatomic, weak, readonly) JustPlayerManager * playerConfigure;
@property (nonatomic, weak) id <JustFFmpegPlayerOutput> playerOutputFF;

+ (instancetype)displayViewWithPlayerConfigure:(JustPlayerManager *)playerConfigure;

@property (nonatomic, weak) id <JustAVPlayerOutput> playerOutputAV;

@property (nonatomic, assign, readonly) JustDisplayPlayerOutputType playerOutputType;
@property (nonatomic, assign, readonly) JustDisplayRendererType rendererType;

- (JustImage *)snapshot;

- (void)reloadGravityMode;
- (void)reloadPlayerConfig;
- (void)reloadVideoFrameForGLFrame:(JustGLKFrame *)glFrame;

- (void)playerOutputTypeAVPlayer;
- (void)playerOutputTypeEmpty;
- (void)playerOutputTypeFF;
- (void)rendererTypeOpenGL;

- (void)rendererTypeEmpty;
- (void)rendererTypeAVPlayerLayer;

@end
