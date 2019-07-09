//
//  JustPlayerDecoder.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustPlayerDecoder.h"

@implementation JustPlayerDecoder

//请在这里设置对应格式的编码类
+ (instancetype)decoderByDefault
{
    JustPlayerDecoder * decoder = [[self alloc] init];
    decoder.decodeTypeForUnknown   = JustDecoderTypeAVPlayer;
    decoder.decodeTypeForMP3       = JustDecoderTypeAVPlayer;
    decoder.decodeTypeForMPEG4     = JustDecoderTypeFFmpeg;
    decoder.decodeTypeForMOV       = JustDecoderTypeAVPlayer;
    decoder.decodeTypeForFLV       = JustDecoderTypeAVPlayer;
    decoder.decodeTypeForM3U8      = JustDecoderTypeAVPlayer;
    decoder.decodeTypeForRTMP      = JustDecoderTypeAVPlayer;
    decoder.decodeTypeForRTSP      = JustDecoderTypeAVPlayer;
    return decoder;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hardwareAccelerateEnableForFFmpeg = YES;
    }
    return self;
}

- (JustMediaFormat)mediaFormatForContentURL:(NSURL *)contentURL
{
    if (!contentURL) return JustMediaFormatError;
    
    NSString * path;
    if (contentURL.isFileURL) {
        path = contentURL.path;
    } else {
        path = contentURL.absoluteString;
    }
    path = [path lowercaseString];
    
    if ([path hasPrefix:@"rtmp:"])
    {
        return JustMediaFormatRTMP;
    }
    else if ([path hasPrefix:@"rtsp:"])
    {
        return JustMediaFormatRTSP;
    }
    else if ([path containsString:@".flv"])
    {
        return JustMediaFormatFLV;
    }
    else if ([path containsString:@".mp4"])
    {
        return JustMediaFormatMPEG4;
    }
    else if ([path containsString:@".mp3"])
    {
        return JustMediaFormatMP3;
    }
    else if ([path containsString:@".m3u8"])
    {
        return JustMediaFormatM3U8;
    }
    else if ([path containsString:@".mov"])
    {
        return JustMediaFormatMOV;
    }
    return JustMediaFormatUnknown;
}

- (JustDecoderType)decoderTypeForContentURL:(NSURL *)contentURL
{
    JustMediaFormat mediaFormat = [self mediaFormatForContentURL:contentURL];
    switch (mediaFormat) {
        case JustMediaFormatError:
            return JustDecoderTypeError;
        case JustMediaFormatUnknown:
            return self.decodeTypeForUnknown;
        case JustMediaFormatMP3:
            return self.decodeTypeForMP3;
        case JustMediaFormatMPEG4:
            return self.decodeTypeForMPEG4;
        case JustMediaFormatMOV:
            return self.decodeTypeForMOV;
        case JustMediaFormatFLV:
            return self.decodeTypeForFLV;
        case JustMediaFormatM3U8:
            return self.decodeTypeForM3U8;
        case JustMediaFormatRTMP:
            return self.decodeTypeForRTMP;
        case JustMediaFormatRTSP:
            return self.decodeTypeForRTSP;
    }
}

@end
