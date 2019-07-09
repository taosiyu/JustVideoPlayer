//
//  JustYUV420Shader.h
//  JustPlayer
//
//  Created by Assassin on 2019/2/19.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustShader.h"

@interface JustYUV420Shader : JustShader

+ (instancetype)program;

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerU_location;
@property (nonatomic, assign) GLint samplerV_location;

@end
