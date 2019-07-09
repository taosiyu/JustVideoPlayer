//
//  JustImage.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>


typedef UIImage JustImage;

JustImage * JustGetImageWithCGImage(CGImageRef image);

// CVPixelBufferRef
JustImage * JustGetImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer);
CIImage * JustGetImageCIImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer);
CGImageRef JustGetImageCGImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer);

// RGB data buffer
JustImage * JustGetImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height);
CGImageRef JustGetImageCGImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height);
