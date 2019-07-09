//
//  JustShader.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/30.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustShader.h"

@interface JustShader ()
{
    GLuint _vertexShader_id;    //顶点着色器ID
    GLuint _fragmentShader_id;  //片元着色器ID
}

@property (nonatomic, copy) NSString * vertexShaderString;    //顶点着色器code
@property (nonatomic, copy) NSString * fragmentShaderString;  //片元着色器code

@end

@implementation JustShader

+ (instancetype)programWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    return [[self alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader];
}

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    if (self = [super init]) {
        self.vertexShaderString = vertexShader;
        self.fragmentShaderString = fragmentShader;
        [self setup];
        [self use];
        [self bindVariable];
    }
    return self;
}

- (void)use
{
    glUseProgram(_program_id);
}

- (void)updateMatrix:(GLKMatrix4)matrix
{
    glUniformMatrix4fv(self.matrix_location, 1, GL_FALSE, matrix.m);
}

#pragma mark - setup

- (void)setup
{
    [self setupProgram];
    [self setupShader];
    [self linkProgram];
    [self setupVariable];
}

- (void)setupProgram
{
    _program_id = glCreateProgram();//glCreateProgram函数创建一个程序
}

- (void)setupShader
{
    // setup shader
    if (![self compileShader:&_vertexShader_id type:GL_VERTEX_SHADER string:self.vertexShaderString.UTF8String])
    {
        NSLog(@"load vertex shader failure");
    }
    if (![self compileShader:&_fragmentShader_id type:GL_FRAGMENT_SHADER string:self.fragmentShaderString.UTF8String])
    {
        NSLog(@"load fragment shader failure");
    }
    //着色器附加到程序对象上
    glAttachShader(_program_id, _vertexShader_id);
    glAttachShader(_program_id, _fragmentShader_id);
}

- (BOOL)linkProgram
{
    GLint status;
    glLinkProgram(_program_id);
//    就像着色器的编译一样，我们也可以检测链接着色器程序是否失败，并获取相应的日志。
//    与上面不同，我们不会调用glGetShaderiv和glGetShaderInfoLog，
    glGetProgramiv(_program_id, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    [self clearShader];
    
    return YES;
}

#pragma mark - clear

- (void)clearShader
{
    if (_vertexShader_id) {
        glDeleteShader(_vertexShader_id);
    }
    
    if (_fragmentShader_id) {
        glDeleteShader(_fragmentShader_id);
    }
}

- (void)clearProgram
{
    if (_program_id) {
        glDeleteProgram(_program_id);
        _program_id = 0;
    }
}

- (void)dealloc
{
    [self clearShader];
    [self clearProgram];
    NSLog(@"%@ release", self.class);
}


#pragma mark - private
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const char *)shaderString
{
    if (!shaderString)
    {
        NSLog(@"Failed to load shader");
        return NO;
    }
    
    GLint status;
    
    //初始化着色器
    * shader = glCreateShader(type);
    glShaderSource(* shader, 1, &shaderString, NULL);
    glCompileShader(* shader);
    glGetShaderiv(* shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE)
    {
        //初始化日志
        GLint logLength;
        glGetShaderiv(* shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar * log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(* shader, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

#pragma mark - must overwrite

- (void)bindVariable {}
- (void)setupVariable {}


@end
