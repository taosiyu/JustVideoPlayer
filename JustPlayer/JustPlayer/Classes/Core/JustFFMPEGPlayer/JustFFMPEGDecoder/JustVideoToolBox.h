//
//  JustVideoToolBox.h
//  JustPlayer
//
//  Created by Assassin on 2019/4/30.
//  Copyright © 2019 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "avformat.h"

@interface JustVideoToolBox : NSObject

+ (instancetype)videoToolBoxWithCodecContext:(AVCodecContext *)codecContext;

- (BOOL)sendPacket:(AVPacket)packet needFlush:(BOOL *)needFlush;
- (CVImageBufferRef)imageBuffer;

- (BOOL)trySetupVTSession;
- (void)flush;

@end
