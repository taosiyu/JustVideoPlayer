//
//  JustTools.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/4.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"
#import "JustImage.h"

typedef NS_ENUM(NSUInteger, JustDecoderErrorCode) {
    JustDecoderErrorCodeFormatCreate,
    JustDecoderErrorCodeFormatOpenInput,
    JustDecoderErrorCodeFormatFindStreamInfo,
    JustDecoderErrorCodeStreamNotFound,
    JustDecoderErrorCodeCodecContextCreate,
    JustDecoderErrorCodeCodecContextSetParam,
    JustDecoderErrorCodeCodecFindDecoder,
    JustDecoderErrorCodeCodecVideoSendPacket,
    JustDecoderErrorCodeCodecAudioSendPacket,
    JustDecoderErrorCodeCodecVideoReceiveFrame,
    JustDecoderErrorCodeCodecAudioReceiveFrame,
    JustDecoderErrorCodeCodecOpen2,
};

/**
 *@获取帧数
 **/
double Just_FFMPEGStreamGetFPS(AVStream * stream, double timebase);

/**
 *@获取steam对应的时间线
 **/
double Just_FFMPEGStreamGetTimebase(AVStream * stream, double default_timebase);

/**
 *@AVDictionary->NSDictionary
 **/
NSDictionary * Just_FFMPEGAVDictionaryToNSDictionary(AVDictionary * avDictionary);

/**
 *@NSDictionary->AVDictionary
 **/
AVDictionary * Just_FFMPEGNSDictionaryToAVDictionary(NSDictionary * dictionary);

/**
 *@获取YUV数据填充时的大小size
 **/
int Just_FFMPEGYUVNeedSize(int linesize, int width, int height, int channel_count);

/**
 *@数据填充
 **/
void Just_FFMPEGYUVFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count);

/**
 *@RGB数据转image
 **/
JustImage * Just_FFMPEGYUVConvertToImage(UInt8 * src_data[], int src_linesize[], int width, int height, enum AVPixelFormat pixelFormat);


#pragma mark - Log Control

#define JustLogEnable     0
