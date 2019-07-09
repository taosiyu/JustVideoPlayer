//
//  JustAudioManager.m
//  JustPlayer
//
//  Created by Assassin on 2019/1/17.
//  Copyright © 2019年 PeachRain. All rights reserved.
//

#import "JustAudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>

//mSampleRate，就是采用频率
//mBitsPerChannel，就是每个采样数据的位数
//mChannelsPerFrame,可以理解为声道数，也就是一个采样时刻产生几个采样数据。
//mFramesPerPacket，就是每个packet的中frame的个数，等于这个packet中经历了几次采样间隔。
//mBytesPerPacket，每个packet中数据的字节数。
//mBytesPerFrame，每个frame中数据的字节数
//
//计算公式
//计算每个packet的持续时间
//
//duration = (1 / mSampleRate) * mFramesPerPacket
//计算mBitsPerChannel
//对于kAudioFormatFlagsCanonical的PCM数据，有以下公式。大概每个采样数据的字节数用AudioSampleType描述。
//
//mBitsPerChannel = 8 * sizeof (AudioSampleType);
//计算mBytesPerFrame
//
//mBytesPerFrame = n * sizeof (AudioSampleType);
//其中n是声道数目

static int const max_frame_size = 4096;

typedef struct
{
    AUNode node;
    AudioUnit audioUnit;
}
JustAudioNodeContext;

typedef struct
{
    AUGraph graph;
    JustAudioNodeContext converterNodeContext;    //格式转换
    JustAudioNodeContext mixerNodeContext;        //混音
    JustAudioNodeContext outputNodeContext;       //输出
    AudioStreamBasicDescription commonFormat;     //对于音频文件的描述
}
JustAudioOutputContext;

@interface JustAudioManager ()
{
    float * _outData;
}

@property (nonatomic, strong) AVAudioSession * audioSession;
@property (nonatomic, weak) id handlerTarget;

@property (nonatomic, copy) JustAudioManagerInterruptionHandler interruptionHandler;
@property (nonatomic, copy) JustAudioManagerRouteChangeHandler routeChangeHandler;

@property (nonatomic, assign) BOOL registered;
@property (nonatomic, strong) NSError * error;


@property (nonatomic, assign) JustAudioOutputContext * outputContext;

@end

@implementation JustAudioManager

+ (instancetype)manager
{
    static JustAudioManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

#pragma mark - init

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_outData = (float *)calloc(max_frame_size * 2, sizeof(float));
        
        self.audioSession = [AVAudioSession sharedInstance];
        // 注册打断通知
        [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(audioSessionInterruptionHandler:) name:AVAudioSessionInterruptionNotification object:nil];
        //添加通知，可自定义拔出耳机后的操作
        [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(audioSessionRouteChangeHandler:) name:AVAudioSessionRouteChangeNotification object:nil];
    }
    return self;
}

#pragma mark - dealloc

- (void)dealloc
{
    [self unregisterAudioSession];
    if (self->_outData) {
        free(self->_outData);
        self->_outData = NULL;
    }
    self->_playing = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - public

- (void)setHandlerTarget:(id)handlerTarget
            interruption:(JustAudioManagerInterruptionHandler)interruptionHandler
             routeChange:(JustAudioManagerRouteChangeHandler)routeChangeHandler
{
    self.handlerTarget = handlerTarget;
    self.interruptionHandler = interruptionHandler;
    self.routeChangeHandler = routeChangeHandler;
}

- (void)removeHandlerTarget:(id)handlerTarget
{
    if (self.handlerTarget == handlerTarget || !self.handlerTarget) {
        self.handlerTarget = nil;
        self.interruptionHandler = nil;
        self.routeChangeHandler = nil;
    }
}

- (void)playWithDelegate:(id<JustAudioManagerDelegate>)delegate
{
    self->_delegate = delegate;
    [self play];
}

- (void)play
{
    if (!self->_playing) {
        if ([self registerAudioSession]) {
            OSStatus result = AUGraphStart(self.outputContext->graph);
            self.error = checkError(result, @"graph start error");
            if (self.error) {
                [self delegateErrorCallback];
            } else {
                self->_playing = YES;
            }
        }
    }
}

- (void)pause
{
    if (self->_playing) {
        OSStatus result = AUGraphStop(self.outputContext->graph);
        self.error = checkError(result, @"graph stop error");
        if (self.error) {
            [self delegateErrorCallback];
        }
        self->_playing = NO;
    }
}

#pragma mark - audio

- (BOOL)registerAudioSession
{
    if (!self.registered) {
        if ([self setupAudioUnit]) {
            self.registered = YES;
        }
    }
    [self.audioSession setActive:YES error:nil];
    return self.registered;
}

//采样频率
- (Float64)samplingRate
{
    if (!self.registered) {
        return 0;
    }
    Float64 number = self.outputContext->commonFormat.mSampleRate;
    if (number > 0) {
        return number;
    }
    return (Float64)self.audioSession.sampleRate;
}

//
- (UInt32)numberOfChannels
{
    if (!self.registered) {
        return 0;
    }
    UInt32 number = self.outputContext->commonFormat.mChannelsPerFrame;
    if (number > 0) {
        return number;
    }
    return (UInt32)self.audioSession.outputNumberOfChannels;
}

- (float)volume
{
    if (self.registered) {
        AudioUnitParameterID param;
        param = kMultiChannelMixerParam_Volume;
        AudioUnitParameterValue volume;
        OSStatus result = AudioUnitGetParameter(self.outputContext->mixerNodeContext.audioUnit,
                                                param,
                                                kAudioUnitScope_Input,
                                                0,
                                                &volume);
        self.error = checkError(result, @"graph get mixer volum error");
        if (self.error) {
            [self delegateErrorCallback];
        } else {
            return volume;
        }
    }
    return 1.f;
}

- (void)setVolume:(float)volume
{
    if (self.registered) {
        AudioUnitParameterID param;
        param = kMultiChannelMixerParam_Volume;
        OSStatus result = AudioUnitSetParameter(self.outputContext->mixerNodeContext.audioUnit,
                                                param,
                                                kAudioUnitScope_Input,
                                                0,
                                                volume,
                                                0);
        self.error = checkError(result, @"graph set mixer volum error");
        if (self.error) {
            [self delegateErrorCallback];
        }
    }
}

#pragma mark - audioUnit init

- (BOOL)setupAudioUnit {
    
    OSStatus result;
    UInt32 audioStreamBasicDescriptionSize = sizeof(AudioStreamBasicDescription);
    
    self.outputContext = (JustAudioOutputContext *)malloc(sizeof(JustAudioOutputContext));
    memset(self.outputContext, 0, sizeof(JustAudioOutputContext));

    //初始化
    result = NewAUGraph(&self.outputContext->graph);
    self.error = checkError(result, @"create graph error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    //格式转换的node
    AudioComponentDescription converterDescription;
    converterDescription.componentType = kAudioUnitType_FormatConverter;
    converterDescription.componentSubType = kAudioUnitSubType_AUConverter;
    converterDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    result = AUGraphAddNode(self.outputContext->graph, &converterDescription, &self.outputContext->converterNodeContext.node);
    self.error = checkError(result, @"graph add converter node error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    //混音的node
    AudioComponentDescription mixerDescription;
    mixerDescription.componentType = kAudioUnitType_Mixer;
    mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    result = AUGraphAddNode(self.outputContext->graph, &mixerDescription, &self.outputContext->mixerNodeContext.node);
    self.error = checkError(result, @"graph add mixer node error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    //输入输出device node
    AudioComponentDescription outputDescription;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    result = AUGraphAddNode(self.outputContext->graph, &outputDescription, &self.outputContext->outputNodeContext.node);
    self.error = checkError(result, @"graph add output node error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    //打开
    result = AUGraphOpen(self.outputContext->graph);
    self.error = checkError(result, @"open graph error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    //其中Element0代表着输出端，Element1代表输入端；每个Element分为Input scope和Output scope
    //参数分别是：AUGraph变量、前一个node、前一个node的element索引、后一个node、后一个node的element索引。
    //conveter 的element 0 链接 mixer 的 elemenet 0
    result = AUGraphConnectNodeInput(self.outputContext->graph,
                                     self.outputContext->converterNodeContext.node,
                                     0,
                                     self.outputContext->mixerNodeContext.node,
                                     0);
    self.error = checkError(result, @"graph connect converter and mixer error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    //outputNodeContext.node element0负责播放
    //mixerNodeContext.node 输出element0
    //把混音结束后的音频流输出给播放组件
    result = AUGraphConnectNodeInput(self.outputContext->graph,
                                     self.outputContext->mixerNodeContext.node,
                                     0,
                                     self.outputContext->outputNodeContext.node,
                                     0);
    self.error = checkError(result, @"graph connect converter and mixer error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    //获取每个node对应的audioUnit信息
    result = AUGraphNodeInfo(self.outputContext->graph,
                             self.outputContext->converterNodeContext.node,
                             &converterDescription,
                             &self.outputContext->converterNodeContext.audioUnit);
    self.error = checkError(result, @"graph get converter audio unit error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    result = AUGraphNodeInfo(self.outputContext->graph,
                             self.outputContext->mixerNodeContext.node,
                             &mixerDescription,
                             &self.outputContext->mixerNodeContext.audioUnit);
    self.error = checkError(result, @"graph get minxer audio unit error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    result = AUGraphNodeInfo(self.outputContext->graph,
                             self.outputContext->outputNodeContext.node,
                             &outputDescription,
                             &self.outputContext->outputNodeContext.audioUnit);
    self.error = checkError(result, @"graph get output audio unit error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    AURenderCallbackStruct converterCallback;
    converterCallback.inputProc = renderCallback;
    converterCallback.inputProcRefCon = (__bridge void *)(self);
    result = AUGraphSetNodeInputCallback(self.outputContext->graph,
                                         self.outputContext->converterNodeContext.node,
                                         0,
                                         &converterCallback);
    self.error = checkError(result, @"graph add converter input callback error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    
    //获取输出流输入端格式
    result = AudioUnitGetProperty(self.outputContext->outputNodeContext.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input, 0,
                                  &self.outputContext->commonFormat,
                                  &audioStreamBasicDescriptionSize);
    self.error = checkError(result, @"get hardware output stream format error");
    if (self.error) {
        [self delegateErrorCallback];
    } else {
        //如果采样频率不一样重新设置采样频率
        if (self.audioSession.sampleRate != self.outputContext->commonFormat.mSampleRate) {
            self.outputContext->commonFormat.mSampleRate = self.audioSession.sampleRate;
            result = AudioUnitSetProperty(self.outputContext->outputNodeContext.audioUnit,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Input,
                                          0,
                                          &self.outputContext->commonFormat,
                                          audioStreamBasicDescriptionSize);
            self.error = checkError(result, @"set hardware output stream format error");
            if (self.error) {
                [self delegateErrorCallback];
            }
        }
    }
    
    //设置转换unit的输入格式
    result = AudioUnitSetProperty(self.outputContext->converterNodeContext.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &self.outputContext->commonFormat,
                                  audioStreamBasicDescriptionSize);
    self.error = checkError(result, @"graph set converter input format error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    result = AudioUnitSetProperty(self.outputContext->converterNodeContext.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  0,
                                  &self.outputContext->commonFormat,
                                  audioStreamBasicDescriptionSize);
    self.error = checkError(result, @"graph set converter output format error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    result = AudioUnitSetProperty(self.outputContext->mixerNodeContext.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &self.outputContext->commonFormat,
                                  audioStreamBasicDescriptionSize);
    self.error = checkError(result, @"graph set mixer input format error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    result = AudioUnitSetProperty(self.outputContext->mixerNodeContext.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  0,
                                  &self.outputContext->commonFormat,
                                  audioStreamBasicDescriptionSize);
    self.error = checkError(result, @"graph set mixer output format error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    result = AudioUnitSetProperty(self.outputContext->mixerNodeContext.audioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &max_frame_size,
                                  sizeof(max_frame_size));
    self.error = checkError(result, @"graph set mixer max frames per slice size error");
    if (self.error) {
        [self delegateErrorCallback];
    }
    
    result = AUGraphInitialize(self.outputContext->graph);
    self.error = checkError(result, @"graph initialize error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    return YES;
}

- (void)unregisterAudioSession
{
    if (self.registered) {
        self.registered = NO;
        OSStatus result = AUGraphUninitialize(self.outputContext->graph);
        self.error = checkError(result, @"graph uninitialize error");
        if (self.error) {
            [self delegateErrorCallback];
        }
        result = AUGraphClose(self.outputContext->graph);
        self.error = checkError(result, @"graph close error");
        if (self.error) {
            [self delegateErrorCallback];
        }
        result = DisposeAUGraph(self.outputContext->graph);
        self.error = checkError(result, @"graph dispose error");
        if (self.error) {
            [self delegateErrorCallback];
        }
        if (self.outputContext) {
            free(self.outputContext);
            self.outputContext = NULL;
        }
    }
}

#pragma mark - notification

- (void)audioSessionInterruptionHandler:(NSNotification *)notification
{
    if (self.handlerTarget && self.interruptionHandler) {
        AVAudioSessionInterruptionType avType = [[notification.userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        id avOption = [notification.userInfo objectForKey:AVAudioSessionInterruptionOptionKey];
        AVAudioSessionInterruptionOptions option = -1;
        if (avOption) {
            AVAudioSessionInterruptionOptions temp = [avOption unsignedIntegerValue];
            if (temp == AVAudioSessionInterruptionOptionShouldResume) {
                option = AVAudioSessionInterruptionOptionShouldResume;
            }
        }
        self.interruptionHandler(self.handlerTarget, self, avType, option);
    }
}

- (void)audioSessionRouteChangeHandler:(NSNotification *)notification
{
    if (self.handlerTarget && self.routeChangeHandler) {
        AVAudioSessionRouteChangeReason avReason = [[notification.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
        switch (avReason) {
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            {
                self.routeChangeHandler(self.handlerTarget, self, AVAudioSessionRouteChangeReasonOldDeviceUnavailable);
//                AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
//                AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
//                //原设备为耳机则暂停
//                if ([portDescription.portType isEqualToString:@"Headphones"]) {
//                    //可以暂停
//                }
            }
                break;
            default:
                break;
        }

    }
}

#pragma mark - audio callback

- (OSStatus)renderFrames:(UInt32)numberOfFrames ioData:(AudioBufferList *)ioData
{
    if (!self.registered) {
        return noErr;
    }
    
    //静音
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
     //填充实际的音频数据
    if (self.playing && self.delegate)
    {
        [self.delegate audioManager:self outputData:self->_outData numberOfFrames:numberOfFrames numberOfChannels:self.numberOfChannels];
        
        UInt32 numBytesPerSample = self.outputContext->commonFormat.mBitsPerChannel / 8;
        if (numBytesPerSample == 4) {
            float zero = 0.0;
            for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                    vDSP_vsadd(self->_outData + iChannel,
                               self.numberOfChannels,
                               &zero,
                               (float *)ioData->mBuffers[iBuffer].mData,
                               thisNumChannels,
                               numberOfFrames);
                }
            }
        }
        else if (numBytesPerSample == 2)
        {
            float scale = (float)INT16_MAX;
            vDSP_vsmul(self->_outData, 1, &scale, self->_outData, 1, numberOfFrames * self.numberOfChannels);
            
            for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                    vDSP_vfix16(self->_outData + iChannel,
                                self.numberOfChannels,
                                (SInt16 *)ioData->mBuffers[iBuffer].mData + iChannel,
                                thisNumChannels,
                                numberOfFrames);
                }
            }
        }
    }
    
    return noErr;
}

static OSStatus renderCallback(void * inRefCon,
                               AudioUnitRenderActionFlags * ioActionFlags,
                               const AudioTimeStamp * inTimeStamp,
                               UInt32 inOutputBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList * ioData)
{
    //ioData是系统开辟的内存空间，用来填充需要播放的音频数据
    JustAudioManager * manager = (__bridge JustAudioManager *)inRefCon;
    return [manager renderFrames:inNumberFrames ioData:ioData];
}

#pragma mark - error

static NSError * checkError(OSStatus result, NSString * domain)
{
    if (result == noErr) return nil;
    NSError * error = [NSError errorWithDomain:domain code:result userInfo:nil];
    return error;
}

- (void)delegateErrorCallback
{
    if (self.error) {
        NSLog(@"JustAudioManager did error : %@", self.error);
    }
}

@end
