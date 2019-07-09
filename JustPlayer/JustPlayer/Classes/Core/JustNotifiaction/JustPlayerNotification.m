//
//  JustPlayerNotification.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustPlayerNotification.h"

@implementation JustPlayerNotification

+ (void)postNotificationPlayer:(JustPlayerManager *)player error:(JustError *)error
{
    if (!player || !error) return;
    NSDictionary * userInfo = @{JustPlayerErrorKey : error};
    player.error = error;
    [self postNotificationName:JustPlayerErrorNotificationName object:player userInfo:userInfo];
}

+ (void)postPlayer:(JustPlayerManager *)player statePrevious:(JustPlayerState)previous current:(JustPlayerState)current
{
    if (!player) return;
    NSDictionary * userInfo = @{
                                JustPlayerPercentKey : @(previous),
                                JustPlayerCurrentKey : @(current)
                                };
    [self postNotificationName:JustPlayerStateChangeNotificationName object:player userInfo:userInfo];
}

+ (void)postPlayer:(JustPlayerManager *)player progressPercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total
{
    if (!player) return;
    if (![percent isKindOfClass:[NSNumber class]]) percent = @(0);
    if (![current isKindOfClass:[NSNumber class]]) current = @(0);
    if (![total isKindOfClass:[NSNumber class]]) total = @(0);
    NSDictionary * userInfo = @{
                                JustPlayerPercentKey : percent,
                                JustPlayerCurrentKey : current,
                                JustPlayerTotalKey : total
                                };
    [self postNotificationName:JustPlayerProgressChangeNotificationName object:player userInfo:userInfo];
}

+ (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo];
    });
}

@end
