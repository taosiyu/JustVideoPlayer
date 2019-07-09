//
//  JustTexture.h
//  JustPlayer
//
//  Created by Assassin on 2019/2/19.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustGLKFrame.h"

@interface JustTexture : NSObject

- (BOOL)updateTextureWithGLFrame:(JustGLKFrame *)glFrame aspect:(CGFloat *)aspect;

- (void)flush;

@end
