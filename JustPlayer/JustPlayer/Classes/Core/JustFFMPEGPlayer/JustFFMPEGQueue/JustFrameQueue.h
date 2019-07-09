//
//  JustFrameQueue.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/8.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustFrame.h"

@interface JustFrameQueue : NSObject

+ (instancetype)frameQueue;

+ (NSTimeInterval)maxVideoDuration;

+ (NSTimeInterval)sleepTimeIntervalForFull;
+ (NSTimeInterval)sleepTimeIntervalForFullAndPaused;

@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) int packetSize;
@property (nonatomic, assign, readonly) NSUInteger count;
@property (atomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign) NSUInteger minFrameCount;    // default is 1.
@property (nonatomic, assign) BOOL ignoreMinFrameCountForGetLimit;

- (void)putFrame:(__kindof JustFrame *)frame;
- (void)putSortFrame:(__kindof JustFrame *)frame;
- (__kindof JustFrame *)getFrameSync;
- (__kindof JustFrame *)getFrameAsync;
- (__kindof JustFrame *)getFrameAsyncPosistion:(NSTimeInterval)position discardFrames:(NSMutableArray <__kindof JustFrame *> **)discardFrames;
- (NSTimeInterval)getFirstFramePositionAsync;
- (NSMutableArray <__kindof JustFrame *> *)discardFrameBeforPosition:(NSTimeInterval)position;

- (void)flush;
- (void)destroy;

@end
