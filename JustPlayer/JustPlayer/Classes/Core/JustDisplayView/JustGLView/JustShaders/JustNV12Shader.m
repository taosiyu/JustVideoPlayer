//
//  JustNV12Shader.m
//  JustPlayer
//
//  Created by Assassin on 2019/5/8.
//  Copyright © 2019 PeachRain. All rights reserved.
//

#import "JustNV12Shader.h"

#define SG_GLES_STRINGIZE(x) #x

static const char vertexShaderString[] = SG_GLES_STRINGIZE
(
     attribute vec4 position;
     attribute vec2 textureCoord;
     uniform mat4 mpv_matrix;
     varying vec2 v_textureCoord;
 
     void main()
     {
         v_textureCoord = textureCoord;
         gl_Position = mpv_matrix * position;
     }
 );

static const char fragmentShaderString[] = SG_GLES_STRINGIZE
(
     precision mediump float;
 
     uniform sampler2D SamplerY;
     uniform sampler2D SamplerUV;
     uniform mat3 colorConversionMatrix;
     varying mediump vec2 v_textureCoord;
 
     void main()
     {
         mediump vec3 yuv;
         
         yuv.x = texture2D(SamplerY, v_textureCoord).r - (16.0/255.0);
         yuv.yz = texture2D(SamplerUV, v_textureCoord).rg - vec2(0.5, 0.5);
         
         lowp vec3 rgb = colorConversionMatrix * yuv;
         
         gl_FragColor = vec4(rgb, 1);
     }
 );

@implementation JustNV12Shader

+ (instancetype)program
{
    return [self programWithVertexShader:[NSString stringWithUTF8String:vertexShaderString]
                          fragmentShader:[NSString stringWithUTF8String:fragmentShaderString]];
}

- (void)bindVariable
{
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.texture_coord_location);
    
    static GLfloat colorConversion709[] = {
        1.164,    1.164,     1.164,
        0.0,      -0.213,    2.112,
        1.793,    -0.533,    0.0,
    };
    glUniformMatrix3fv(self.colorConversionMatrix_location, 1, GL_FALSE, colorConversion709);
    
    glUniform1i(self.samplerY_location, 0);
    glUniform1i(self.samplerUV_location, 1);
    
//    FFmpeg的AV_PIX_FMT_YUV420P:AVFrame的data数组有三个，分别是YUV三分量
//    AV_PIX_FMT_NV12则只有 data[0]和data1，分别是Y分量和UV分量
}

- (void)setupVariable
{
    //opengl属性绑定Object-c属性
    self.position_location = glGetAttribLocation(self.program_id, "position");
    self.texture_coord_location = glGetAttribLocation(self.program_id, "textureCoord");
    self.matrix_location = glGetUniformLocation(self.program_id, "mpv_matrix");
    
    self.samplerY_location = glGetUniformLocation(self.program_id, "SamplerY");
    self.samplerUV_location = glGetUniformLocation(self.program_id, "SamplerUV");
    self.colorConversionMatrix_location = glGetUniformLocation(self.program_id, "colorConversionMatrix");
}

@end










