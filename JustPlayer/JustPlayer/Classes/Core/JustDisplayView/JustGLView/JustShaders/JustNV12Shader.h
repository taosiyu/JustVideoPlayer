//
//  JustNV12Shader.h
//  JustPlayer
//
//  Created by Assassin on 2019/5/8.
//  Copyright © 2019 PeachRain. All rights reserved.
//

#import "JustShader.h"

@interface JustNV12Shader : JustShader

+ (instancetype)program;

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerUV_location;
@property (nonatomic, assign) GLint colorConversionMatrix_location;

@end
