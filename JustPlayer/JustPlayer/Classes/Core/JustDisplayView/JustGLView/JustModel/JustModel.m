//
//  JustModel.m
//  JustPlayer
//
//  Created by Assassin on 2019/4/2.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustModel.h"

@implementation JustModel

+ (instancetype)model
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupModel];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%@ release", self.class);
}

#pragma mark - subclass override

- (void)setupModel {}
- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation {}
- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(JustGLModelTextureRotateType)textureRotateType {}


@end
