//
//  JustMetadata.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavutil/dict.h>

@interface JustMetadata : NSObject

+ (instancetype)metadataWithAVDictionary:(AVDictionary *)avDictionary;

@property (nonatomic, strong) NSDictionary * metadata;

@property (nonatomic, copy) NSString * language;
@property (nonatomic, assign) long long BPS;
@property (nonatomic, copy) NSString * duration;
@property (nonatomic, assign) long long number_of_bytes;
@property (nonatomic, assign) long long number_of_frames;

@end
