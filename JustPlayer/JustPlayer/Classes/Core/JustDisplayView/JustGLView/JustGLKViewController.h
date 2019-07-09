//
//  JustGLKViewController.h
//  JustPlayer
//
//  Created by Assassin on 2019/1/18.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "JustDisplayView.h"

@interface JustGLKViewController : GLKViewController

@property (nonatomic, weak, readonly) JustDisplayView * displayView;

+ (instancetype)viewControllerWithDisplayView:(JustDisplayView *)displayView;

- (void)reloadViewport;

- (JustImage *)snapshot;

@end
