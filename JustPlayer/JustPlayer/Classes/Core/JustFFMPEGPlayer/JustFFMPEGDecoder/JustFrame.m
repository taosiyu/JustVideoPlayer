//
//  JustFrame.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/8.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustFrame.h"

@implementation JustFrame

- (void)startPlaying
{
    self->_playing = YES;
    if ([self.delegate respondsToSelector:@selector(frameDidStartPlaying:)]) {
        [self.delegate frameDidStartPlaying:self];
    }
}

- (void)stopPlaying
{
    self->_playing = NO;
    if ([self.delegate respondsToSelector:@selector(frameDidStopPlaying:)]) {
        [self.delegate frameDidStopPlaying:self];
    }
}

- (void)cancel
{
    self->_playing = NO;
    if ([self.delegate respondsToSelector:@selector(frameDidCancel:)]) {
        [self.delegate frameDidCancel:self];
    }
}


@end
