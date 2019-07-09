//
//  JustAudioFrame.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/15.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustAudioFrame.h"

@interface JustAudioFrame ()
{
    size_t buffer_size;   //数据大小
}

@end

@implementation JustAudioFrame

- (JustFrameType)type
{
    return JustFrameTypeAudio;
}

- (int)size
{
    return (int)self->length;
}

- (void)setSamplesLength:(NSUInteger)samplesLength
{
    if (self->buffer_size < samplesLength) {
        if (self->buffer_size > 0 && self->samples != NULL) {
            free(self->samples);
        }
        self->buffer_size = samplesLength;
        self->samples = malloc(self->buffer_size);
    }
    self->length = (int)samplesLength;
    self->output_offset = 0;
}

- (void)dealloc
{
    if (self->buffer_size > 0 && self->samples != NULL) {
        free(self->samples);
    }
}


@end
