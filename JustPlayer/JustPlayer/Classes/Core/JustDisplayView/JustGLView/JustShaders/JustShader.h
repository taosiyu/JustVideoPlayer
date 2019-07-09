//
//  JustShader.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/30.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>
#import <GLKit/GLKit.h>

@interface JustShader : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)programWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;

@property (nonatomic, assign) GLint program_id;
@property (nonatomic, assign) GLint position_location;
@property (nonatomic, assign) GLint texture_coord_location;
@property (nonatomic, assign) GLint matrix_location;

- (void)updateMatrix:(GLKMatrix4)matrix;
- (void)use;

- (void)setupVariable;
- (void)bindVariable;

@end
