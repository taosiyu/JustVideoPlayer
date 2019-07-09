//
//  JustPlayerModels.h
//  JustPlayer
//
//  Created by PeachRain on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JustErrorEvent : NSObject
@property (nonatomic, copy, nullable) NSDate * date;
@property (nonatomic, copy, nullable) NSString * URI;
@property (nonatomic, copy, nullable) NSString * serverAddress;
@property (nonatomic, copy, nullable) NSString * playbackSessionID;
@property (nonatomic, assign) NSInteger errorStatusCode;
@property (nonatomic, copy) NSString * errorDomain;
@property (nonatomic, copy, nullable) NSString * errorComment;
@end

@interface JustError : NSObject
@property (nonatomic, copy) NSError * error;
@property (nonatomic, copy, nullable) NSData * extendedLogData;
@property (nonatomic, assign) NSStringEncoding extendedLogDataStringEncoding;
@property (nonatomic, copy, nullable) NSArray <JustErrorEvent *> * errorEvents;
@end
