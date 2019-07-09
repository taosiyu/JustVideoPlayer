//
//  JustFramePool.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/8.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustFramePool.h"

@interface JustFramePool () <JustFrameDelegate>

@property (nonatomic, copy) Class frameClassName;
@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) JustFrame * playingFrame;
@property (nonatomic, strong) NSMutableSet <JustFrame *> * unuseFrames;
@property (nonatomic, strong) NSMutableSet <JustFrame *> * usedFrames;

@end

@implementation JustFramePool

+ (instancetype)videoPool
{
    return [self poolWithCapacity:60 frameClassName:NSClassFromString(@"JustYUVVideoFrame")];
}

+ (instancetype)audioPool
{
    return [self poolWithCapacity:500 frameClassName:NSClassFromString(@"JustAudioFrame")];
}

+ (instancetype)poolWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName
{
    return [[self alloc] initWithCapacity:number frameClassName:frameClassName];
}

- (instancetype)initWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName
{
    if (self = [super init]) {
        self.frameClassName = frameClassName;
        self.lock = [[NSLock alloc] init];
        self.unuseFrames = [NSMutableSet setWithCapacity:number];
        self.usedFrames = [NSMutableSet setWithCapacity:number];
    }
    return self;
}

- (NSUInteger)count
{
    return [self unuseCount] + [self usedCount] + (self.playingFrame ? 1 : 0);
}

- (NSUInteger)unuseCount
{
    return self.unuseFrames.count;
}

- (NSUInteger)usedCount
{
    return self.usedFrames.count;
}

- (__kindof JustFrame *)getUnuseFrame
{
    [self.lock lock];
    JustFrame * frame;
    if (self.unuseFrames.count > 0) {
        frame = [self.unuseFrames anyObject];
        [self.unuseFrames removeObject:frame];
        [self.usedFrames addObject:frame];
        
    } else {
        frame = [[self.frameClassName alloc] init];
        frame.delegate = self;
        [self.usedFrames addObject:frame];
    }
    [self.lock unlock];
    return frame;
}

- (void)setFrameUnuse:(JustFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:self.frameClassName]) return;
    [self.lock lock];
    [self.unuseFrames addObject:frame];
    [self.usedFrames removeObject:frame];
    [self.lock unlock];
}

- (void)setFramesUnuse:(NSArray <JustFrame *> *)frames
{
    if (frames.count <= 0) return;
    [self.lock lock];
    for (JustFrame * obj in frames) {
        if (![obj isKindOfClass:self.frameClassName]) continue;
        [self.usedFrames removeObject:obj];
        [self.unuseFrames addObject:obj];
    }
    [self.lock unlock];
}

- (void)setFrameStartDrawing:(JustFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:self.frameClassName]) return;
    [self.lock lock];
    if (self.playingFrame) {
        [self.unuseFrames addObject:self.playingFrame];
    }
    self.playingFrame = frame;
    [self.usedFrames removeObject:self.playingFrame];
    [self.lock unlock];
}

- (void)setFrameStopDrawing:(JustFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:self.frameClassName]) return;
    [self.lock lock];
    if (self.playingFrame == frame) {
        [self.unuseFrames addObject:self.playingFrame];
        self.playingFrame = nil;
    }
    [self.lock unlock];
}

- (void)flush
{
    [self.lock lock];
    [self.usedFrames enumerateObjectsUsingBlock:^(JustFrame * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.unuseFrames addObject:obj];
    }];
    [self.usedFrames removeAllObjects];
    [self.lock unlock];
}

#pragma mark - SGFFFrameDelegate

- (void)frameDidStartPlaying:(JustFrame *)frame
{
    [self setFrameStartDrawing:frame];
}

- (void)frameDidStopPlaying:(JustFrame *)frame
{
    [self setFrameStopDrawing:frame];
}

- (void)frameDidCancel:(JustFrame *)frame
{
    [self setFrameUnuse:frame];
}

@end
