//
//  JustFrame.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/8.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustFrame.h"

typedef NS_ENUM(NSUInteger, JustFrameType) {
    JustFrameTypeVideo,
    JustFrameTypeAVYUVVideo,
    JustFFFrameTypeCVYUVVideo,
    JustFrameTypeAudio,
    JustFrameTypeSubtitle,
};

@class JustFrame;

@protocol JustFrameDelegate <NSObject>

- (void)frameDidStartPlaying:(JustFrame *)frame;
- (void)frameDidStopPlaying:(JustFrame *)frame;
- (void)frameDidCancel:(JustFrame *)frame;

@end

@interface JustFrame : NSObject

@property (nonatomic, weak) id <JustFrameDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL playing;

@property (nonatomic, assign) JustFrameType type;
@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign) int packetSize;

- (void)startPlaying;
- (void)stopPlaying;
- (void)cancel;

@end
