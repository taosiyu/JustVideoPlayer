//
//  JustModel.h
//  JustPlayer
//
//  Created by Assassin on 2019/4/2.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, JustGLModelTextureRotateType) {
    JustGLModelTextureRotateType0,
    JustGLModelTextureRotateType90,
    JustGLModelTextureRotateType180,
    JustGLModelTextureRotateType270,
};

@interface JustModel : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)model;

@property (nonatomic, assign) GLuint index_id;
@property (nonatomic, assign) GLuint vertex_id;
@property (nonatomic, assign) GLuint texture_id;

@property (nonatomic, assign) int index_count;
@property (nonatomic, assign) int vertex_count;

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation;

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(JustGLModelTextureRotateType)textureRotateType;


- (void)setupModel;

@end

NS_ASSUME_NONNULL_END
