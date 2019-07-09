//
//  JustTrack.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/7.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustMetadata.h"

typedef NS_ENUM(NSUInteger, JustTrackType) {
    JustTrackTypeVideo,
    JustTrackTypeAudio,
    JustTrackTypeSubtitle,
};

@interface JustTrack : NSObject

@property (nonatomic, assign) int index;
@property (nonatomic, assign) JustTrackType type;
@property (nonatomic, strong) JustMetadata * metadata;

@end
