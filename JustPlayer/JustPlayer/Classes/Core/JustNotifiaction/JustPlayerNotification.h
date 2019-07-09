//
//  JustPlayerNotification.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JustPlayerConfigure.h"
#import "JustPlayerDefine.h"

@interface JustPlayerNotification : NSObject

+ (void)postNotificationPlayer:(JustPlayerManager *)player error:(JustError *)error;

+ (void)postPlayer:(JustPlayerManager *)player statePrevious:(JustPlayerState)previous current:(JustPlayerState)current;

+ (void)postPlayer:(JustPlayerManager *)player progressPercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total;

@end
