//
//  JustAudioFrame.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/15.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustFrame.h"

@interface JustAudioFrame : JustFrame
{
@public
    float * samples;       //音频数据
    int length;
    int output_offset;
}

- (void)setSamplesLength:(NSUInteger)samplesLength;

@end
