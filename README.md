# JustVideoPlayer
a simple tool for play video by FFMPEG

![language](https://img.shields.io/badge/language-object--c-yellow.svg) ![support](https://img.shields.io/badge/support-IOS%208%2B-green.svg)

> ios端易用的本地视频播放器， 通过它，可以播放本地视频.

### 架构

如图：
![justPlayer](https://github.com/taosiyu/JustVideoPlayer/raw/master/img/img1.jpeg)

## 特性

1. 目前只完成了FFMPEG的软解能力
2. 后续会支持ios硬编码
3. 本版本已经编译集成了FFMPEG(H264),模拟器和真机都支持

## 示例

本示例直接运行就可以，自带一段示例视频

### 注意
![justPlayer](https://github.com/taosiyu/JustVideoPlayer/raw/master/img/img2)
在配置中，请配置对应的格式所对应的解码方式(AVPlayer或者FFMPEG)

## 如何使用
```
@property (nonatomic, strong) JustPlayerManager * player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //使用方案
    self.view.backgroundColor = [UIColor blackColor];
    self.player = [JustPlayerManager player];
    [self.view insertSubview:self.player.view atIndex:0];
    NSURL *normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"铠甲" ofType:@"mp4"]];
    [self.player replaceVideoWithURL:normalVideo];
    __weak typeof(self)weakSelf = self;
    [self.player setViewTapAction:^(JustPlayerManager *player, UIView *view) {
    //这里是点击屏幕的事件
         __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf tap];
    }];
}
```