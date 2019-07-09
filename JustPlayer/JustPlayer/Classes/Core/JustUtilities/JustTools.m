//
//  JustTools.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/4.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustTools.h"
#import <libswscale/swscale.h>
#import <libavutil/imgutils.h>


//log
void JustLog(void * context, int level, const char * format, va_list args)
{
#if JustLogEnable
    NSString * message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args];
    NSlog(@"JustLog : %@", message);
#endif
}

//获取帧数
double Just_FFMPEGStreamGetFPS(AVStream * stream, double timebase)
{
    double fps;
    //分数转小数
    if (stream->avg_frame_rate.den > 0 && stream->avg_frame_rate.num > 0) {
        fps = av_q2d(stream->avg_frame_rate);
    } else if (stream->r_frame_rate.den > 0 && stream->r_frame_rate.num > 0) {
        fps = av_q2d(stream->r_frame_rate);
    } else {
        fps = 1.0 / timebase;
    }
    return fps;
}

//获取steam对应的时间线
double Just_FFMPEGStreamGetTimebase(AVStream * stream, double default_timebase)
{
    double timebase;
    if (stream->time_base.den > 0 && stream->time_base.num > 0) {
        timebase = av_q2d(stream->time_base);
    } else {
        timebase = default_timebase;
    }
    return timebase;
}

//AVDictionary->NSDictionary
NSDictionary * Just_FFMPEGAVDictionaryToNSDictionary(AVDictionary * avDictionary)
{
    if (avDictionary == NULL) return nil;
    
    int count = av_dict_count(avDictionary);
    if (count <= 0) return nil;
    
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    AVDictionaryEntry * entry = NULL;
    while ((entry = av_dict_get(avDictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        @autoreleasepool {
            NSString * key = [NSString stringWithUTF8String:entry->key];
            NSString * value = [NSString stringWithUTF8String:entry->value];
            [dictionary setObject:value forKey:key];
        }
    }
    
    return dictionary;
}

//NSDictionary->AVDictionary
AVDictionary * Just_FFMPEGNSDictionaryToAVDictionary(NSDictionary * dictionary)
{
    if (dictionary.count <= 0) {
        return NULL;
    }
    
    __block BOOL success = NO;
    __block AVDictionary * dict = NULL;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            av_dict_set_int(&dict, [key UTF8String], [obj integerValue], 0);
            success = YES;
        } else if ([obj isKindOfClass:[NSString class]]) {
            av_dict_set(&dict, [key UTF8String], [obj UTF8String], 0);
            success = YES;
        }
    }];
    if (success) {
        return dict;
    }
    return NULL;
}

int Just_FFMPEGYUVNeedSize(int linesize, int width, int height, int channel_count)
{
    width = MIN(linesize, width);
    return width * height * channel_count;
}

void Just_FFMPEGYUVFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count)
{
    width = MIN(linesize, width);
    UInt8 * temp = dst;
    memset(dst, 0, dstsize);
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, width * channel_count);
        temp += (width * channel_count);
        src += linesize;
    }
}

JustImage * Just_FFMPEGYUVConvertToImage(UInt8 * src_data[], int src_linesize[], int width, int height, enum AVPixelFormat pixelFormat)
{
    struct SwsContext * sws_context = NULL;
    //初始化转换器和缩放器
    sws_context = sws_getCachedContext(sws_context,
                                       width,
                                       height,
                                       pixelFormat,
                                       width,
                                       height,
                                       AV_PIX_FMT_RGB24,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    if (!sws_context) return nil;
    
    uint8_t * data[AV_NUM_DATA_POINTERS];
    int linesize[AV_NUM_DATA_POINTERS];
    
    int result = av_image_alloc(data, linesize, width, height, AV_PIX_FMT_RGB24, 1);
    if (result < 0) {
        if (sws_context) {
            sws_freeContext(sws_context);
        }
        return nil;
    }
    //用sws_scale可能会增加Cpu的压力
    result = sws_scale(sws_context, (const uint8_t **)src_data, src_linesize, 0, height, data, linesize);
    if (sws_context) {
        sws_freeContext(sws_context);
    }
    if (result < 0) return nil;
    if (linesize[0] <= 0 || data[0] == NULL) return nil;
    
    JustImage * image = JustGetImageWithRGBData(data[0], linesize[0], width, height);
    av_freep(&data[0]);
    
    return image;
}


