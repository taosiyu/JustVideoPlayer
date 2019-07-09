//
//  JustFramePool.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/8.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustFrame.h"

@interface JustFramePool : NSObject

+ (instancetype)videoPool;
+ (instancetype)audioPool;
+ (instancetype)poolWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName;

- (NSUInteger)count;
- (NSUInteger)unuseCount;
- (NSUInteger)usedCount;

- (__kindof JustFrame *)getUnuseFrame;

- (void)flush;

@end
