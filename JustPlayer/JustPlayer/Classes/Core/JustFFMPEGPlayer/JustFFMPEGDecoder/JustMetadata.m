//
//  JustMetadata.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustMetadata.h"
#import "JustTools.h"

@implementation JustMetadata

+ (instancetype)metadataWithAVDictionary:(AVDictionary *)avDictionary
{
    return [[self alloc] initWithAVDictionary:avDictionary];
}

- (instancetype)initWithAVDictionary:(AVDictionary *)avDictionary
{
    if (self = [super init])
    {
        NSDictionary * dic = Just_FFMPEGAVDictionaryToNSDictionary(avDictionary);
        
        self.metadata = dic;
        
        self.language = [dic objectForKey:@"language"];                                      //语言
        self.BPS = [[dic objectForKey:@"BPS"] longLongValue];                                //比特率
        self.duration = [dic objectForKey:@"DURATION"];                                      //时间
        self.number_of_bytes = [[dic objectForKey:@"NUMBER_OF_BYTES"] longLongValue];        //bytes
        self.number_of_frames = [[dic objectForKey:@"NUMBER_OF_FRAMES"] longLongValue];      //帧总数
    }
    return self;
}

@end
