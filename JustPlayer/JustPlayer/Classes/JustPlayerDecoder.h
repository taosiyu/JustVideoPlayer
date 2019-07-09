//
//  JustPlayerDecoder.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>

// decode type
typedef NS_ENUM(NSUInteger, JustDecoderType) {
    JustDecoderTypeError,
    JustDecoderTypeAVPlayer,
    JustDecoderTypeFFmpeg,
};

// media format
typedef NS_ENUM(NSUInteger, JustMediaFormat) {
    JustMediaFormatError,
    JustMediaFormatUnknown,
    JustMediaFormatMP3,
    JustMediaFormatMPEG4,
    JustMediaFormatMOV,
    JustMediaFormatFLV,
    JustMediaFormatM3U8,
    JustMediaFormatRTMP,
    JustMediaFormatRTSP,
};

@interface JustPlayerDecoder : NSObject

@property (nonatomic, assign) BOOL hardwareAccelerateEnableForFFmpeg;  // default is YES

@property (nonatomic, assign) JustDecoderType decodeTypeForUnknown;
@property (nonatomic, assign) JustDecoderType decodeTypeForMP3;
@property (nonatomic, assign) JustDecoderType decodeTypeForMPEG4;
@property (nonatomic, assign) JustDecoderType decodeTypeForMOV;
@property (nonatomic, assign) JustDecoderType decodeTypeForFLV;
@property (nonatomic, assign) JustDecoderType decodeTypeForM3U8;
@property (nonatomic, assign) JustDecoderType decodeTypeForRTMP;
@property (nonatomic, assign) JustDecoderType decodeTypeForRTSP;

+ (instancetype)decoderByDefault;
- (JustDecoderType)decoderTypeForContentURL:(NSURL *)contentURL;

@end
