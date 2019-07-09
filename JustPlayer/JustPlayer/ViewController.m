//
//  ViewController.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/3.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "ViewController.h"
#import "JustPlayerConfigure.h"

@interface ViewController ()

@property (nonatomic, strong) JustPlayerManager * player;

@property (nonatomic,assign)BOOL isPlaying;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //使用方案
    self.view.backgroundColor = [UIColor blackColor];
    self.player = [JustPlayerManager player];
    [self.view insertSubview:self.player.view atIndex:0];
//    NSURL *normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"铠甲" ofType:@"mp4"]];
    NSURL *normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"铠甲" ofType:@"MOV"]];
    [self.player replaceVideoWithURL:normalVideo];
    __weak typeof(self)weakSelf = self;
    [self.player setViewTapAction:^(JustPlayerManager *player, UIView *view) {
         __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf tap];
    }];
    
    //旋转动画
    [self animation];
}

- (void)animation{
    CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    basicAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    basicAnimation.toValue = [NSNumber numberWithFloat:1.5];
    basicAnimation.autoreverses = YES;
    basicAnimation.removedOnCompletion = NO;
    basicAnimation.duration = 5;
    basicAnimation.repeatCount = MAXFLOAT;
    [self.player.view.layer addAnimation:basicAnimation forKey:@"AnimationMoveY"];
    
}

- (void)tap {
    if ( _isPlaying == YES) {
        //暂停
        [self.player pause];
    }else{
        //开始
        [self.player play];
    }
    _isPlaying = !_isPlaying;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.player.view.frame = self.view.bounds;
}


@end
