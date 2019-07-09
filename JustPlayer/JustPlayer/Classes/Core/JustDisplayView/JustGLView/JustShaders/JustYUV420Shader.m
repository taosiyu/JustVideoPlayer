//
//  JustYUV420Shader.m
//  JustPlayer
//
//  Created by PeachRain on 2019/2/19.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustYUV420Shader.h"

#define SG_GLES_STRINGIZE(x) #x

static const char vertexShaderString[] = SG_GLES_STRINGIZE
(
 attribute vec4 position;
 attribute vec2 textureCoord;
 uniform mat4 mvp_matrix;
 varying vec2 v_textureCoord;
 
 void main()
 {
     v_textureCoord = textureCoord;
     gl_Position = mvp_matrix * position;
 }
 );

static const char fragmentShaderString[] = SG_GLES_STRINGIZE
(
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerU;
 uniform sampler2D SamplerV;
 varying mediump vec2 v_textureCoord;
 
 void main()
 {
     highp float y = texture2D(SamplerY, v_textureCoord).r;
     highp float u = texture2D(SamplerU, v_textureCoord).r - 0.5;
     highp float v = texture2D(SamplerV, v_textureCoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
     gl_FragColor = vec4(r , g, b, 1.0);
 }
 );

@implementation JustYUV420Shader

+ (instancetype)program
{
    return [self programWithVertexShader:[NSString stringWithUTF8String:vertexShaderString]
                          fragmentShader:[NSString stringWithUTF8String:fragmentShaderString]];
}

- (void)bindVariable
{
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.texture_coord_location);
    
    glUniform1i(self.samplerY_location, 0);
    glUniform1i(self.samplerU_location, 1);
    glUniform1i(self.samplerV_location, 2);
    //    FFmpeg的AV_PIX_FMT_YUV420P:AVFrame的data数组有三个，分别是YUV三分量
    //    AV_PIX_FMT_NV12则只有 data[0]和data1，分别是Y分量和UV分量
    //
}

- (void)setupVariable
{
    self.position_location = glGetAttribLocation(self.program_id, "position");
    self.texture_coord_location = glGetAttribLocation(self.program_id, "textureCoord");
    self.matrix_location = glGetUniformLocation(self.program_id, "mvp_matrix");
    self.samplerY_location = glGetUniformLocation(self.program_id, "SamplerY");
    self.samplerU_location = glGetUniformLocation(self.program_id, "SamplerU");
    self.samplerV_location = glGetUniformLocation(self.program_id, "SamplerV");
}

@end
