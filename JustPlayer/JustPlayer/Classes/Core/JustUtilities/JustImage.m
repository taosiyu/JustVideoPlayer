//
//  JustImage.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustImage.h"

JustImage * JustGetImageWithCGImage(CGImageRef image)
{
    return [UIImage imageWithCGImage:image];
}

JustImage * JustGetImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage * ciImage = JustGetImageCIImageWithCVPexelBuffer(pixelBuffer);
    if (!ciImage) return nil;
    return [UIImage imageWithCIImage:ciImage];
}

CIImage * JustGetImageCIImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage * image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    return image;
}

CGImageRef JustGetImageCGImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer)
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t count = CVPixelBufferGetPlaneCount(pixelBuffer);
    if (count > 1) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return nil;
    }
    
    uint8_t * baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return imageRef;
}

JustImage * JustGetImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height)
{
    CGImageRef imageRef = JustGetImageCGImageWithRGBData(rgb_data, linesize, width, height);
    if (!imageRef) return nil;
    JustImage * image = JustGetImageWithCGImage(imageRef);
    CGImageRelease(imageRef);
    return image;
}

CGImageRef JustGetImageCGImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height)
{
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, rgb_data, linesize * height);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        8,
                                        24,
                                        linesize,
                                        colorSpace,
                                        kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        NO,
                                        kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return imageRef;
}
