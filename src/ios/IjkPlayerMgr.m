/*
 * Apache 2.0 License
 *
 * Copyright (c) Hao Lin 2019
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apache License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://opensource.org/licenses/Apache-2.0/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 */

// codebeat:disable[TOO_MANY_FUNCTIONS]

#import "IjkPlayerMgr.h"

@interface IjkPlayerMgr ()

@property (nonatomic, retain) CDVInvokedUrlCommand *cdvInvokedUrlCommand;

@property (nonatomic, retain) UIView *playerRootView;
@property (nonatomic, retain) IJKFFMoviePlayerController *ijkPlayer;
@property (nonatomic, retain) NSString *currentVideoUrl;

@property (nonatomic, assign) BOOL isReconnect;
@property (nonatomic, retain) UIView *playerRootViewReconnect;
@property (nonatomic, retain) IJKFFMoviePlayerController *ijkPlayerReconnect;
@property (nonatomic, retain) NSString *reconnectVideoUrl;

@property (nonatomic, assign) double videoViewX;
@property (nonatomic, assign) double videoViewY;
@property (nonatomic, assign) double videoViewWidth;
@property (nonatomic, assign) double videoViewHeight;


- (IJKFFOptions *)optionsByDefault;
- (UIView *) createVideoView;

@end

@implementation IjkPlayerMgr
@synthesize cdvInvokedUrlCommand;
@synthesize playerRootView, ijkPlayer, currentVideoUrl;
@synthesize isReconnect, playerRootViewReconnect, ijkPlayerReconnect, reconnectVideoUrl;
@synthesize videoViewX, videoViewY, videoViewWidth, videoViewHeight;

#pragma mark -
#pragma mark Interface

- (void) playVideo:(CDVInvokedUrlCommand*)command{
    if(command.arguments == nil || command.arguments.count == 0){
        return;
    }
    NSString *videoUrl = command.arguments[0];
    if(videoUrl == nil){
        return;
    }
    
    [self stopReconnect];
    
    if(self.ijkPlayer != nil){
        [self removeMovieNotificationObservers:self.ijkPlayer];
        [self.ijkPlayer shutdown];
        UIView *ijkView = [self.ijkPlayer view];
        [ijkView removeFromSuperview];
        self.ijkPlayer = nil;
        [self.playerRootView removeFromSuperview];
        self.playerRootView = nil;
    }
    self.cdvInvokedUrlCommand = command;
    self.playerRootView = [self createVideoView];
    self.playerRootView.backgroundColor = [UIColor blackColor];
    
    self.ijkPlayer = [[IJKFFMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString: videoUrl]
                                                                withOptions:[self optionsByDefault]];
    if(self.ijkPlayer != nil){
        self.ijkPlayer.liveOpenDelegate = self;
        self.ijkPlayer.tcpOpenDelegate = self;
        self.ijkPlayer.segmentOpenDelegate = self;
        self.ijkPlayer.nativeInvokeDelegate = self;
        
        [self.ijkPlayer setScalingMode:IJKMPMovieScalingModeFill];
        UIView *ijkView = [self.ijkPlayer view];
        ijkView.frame = self.playerRootView.bounds;
        ijkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.playerRootView addSubview:ijkView];
        
        UIWindow * window = [[UIApplication sharedApplication] keyWindow];
        UIView *rootView = [[window subviews] objectAtIndex:0];
        [rootView insertSubview:self.playerRootView atIndex:1];
        [self installMovieNotificationObservers:self.ijkPlayer];
        [self.ijkPlayer prepareToPlay];
        self.currentVideoUrl = videoUrl;
    }
}

- (void) playVideoForReconnect:(NSString *)videoUrl{
    if(videoUrl == nil){
        self.isReconnect = false;
        return;
    }
    
    if(self.ijkPlayerReconnect != nil){
        [self removeMovieNotificationObservers:self.ijkPlayerReconnect];
        [self.ijkPlayerReconnect shutdown];
        UIView *ijkView = [self.ijkPlayerReconnect view];
        [ijkView removeFromSuperview];
        self.ijkPlayerReconnect = nil;
        [self.playerRootViewReconnect removeFromSuperview];
        self.playerRootViewReconnect = nil;
    }

    self.playerRootViewReconnect = [self createVideoView];
    self.playerRootViewReconnect.backgroundColor = [UIColor blackColor];
    self.ijkPlayerReconnect = [[IJKFFMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString: videoUrl]
                                                                withOptions:[self optionsByDefault]];
    if(self.ijkPlayerReconnect != nil){
        self.ijkPlayerReconnect.liveOpenDelegate = self;
        self.ijkPlayerReconnect.tcpOpenDelegate = self;
        self.ijkPlayerReconnect.segmentOpenDelegate = self;
        self.ijkPlayerReconnect.nativeInvokeDelegate = self;

        [self.ijkPlayerReconnect setScalingMode:IJKMPMovieScalingModeFill];
        UIView *ijkView = [self.ijkPlayerReconnect view];
        ijkView.frame = self.playerRootViewReconnect.bounds;
        ijkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.playerRootViewReconnect addSubview:ijkView];
        
        UIWindow * window = [[UIApplication sharedApplication] keyWindow];
        UIView *rootView = [[window subviews] objectAtIndex:0];
        [rootView insertSubview:self.playerRootViewReconnect atIndex:0];
        [self installMovieNotificationObservers:self.ijkPlayerReconnect];
        [self.ijkPlayerReconnect prepareToPlay];
        self.reconnectVideoUrl = videoUrl;
    }else{
        self.isReconnect = false;
    }
}

- (void) removeVideo:(CDVInvokedUrlCommand*)command{
    [self stopReconnect];
    if(self.ijkPlayer != nil){
        [self removeMovieNotificationObservers: self.ijkPlayer];
        [self.ijkPlayer shutdown];
        UIView *ijkView = [self.ijkPlayer view];
        [ijkView removeFromSuperview];
        self.ijkPlayer = nil;
        [self.playerRootView removeFromSuperview];
        self.playerRootView = nil;
        self.cdvInvokedUrlCommand = nil;
    }
}

- (void) disconnectVideo:(CDVInvokedUrlCommand*)command{
    [self stopReconnect];
    if(self.ijkPlayer != nil){
        [self removeMovieNotificationObservers: self.ijkPlayer];
        [self.ijkPlayer shutdown];
        UIView *ijkView = [self.ijkPlayer view];
        [ijkView removeFromSuperview];
        self.ijkPlayer = nil;
        [self.playerRootView removeFromSuperview];
        self.playerRootView = nil;
        self.cdvInvokedUrlCommand = nil;
    }
}

- (void)stopReconnect{
    if(self.isReconnect){
        self.isReconnect = false;
        if(self.reconnectVideoUrl){
            self.reconnectVideoUrl = nil;
        }
        if(self.ijkPlayerReconnect != nil){
            [self removeMovieNotificationObservers: self.ijkPlayerReconnect];
            [self.ijkPlayerReconnect shutdown];
            self.ijkPlayerReconnect = nil;
            [self.playerRootViewReconnect removeFromSuperview];
            self.playerRootViewReconnect = nil;
        }
    }
}

- (void)reconnectVideo:(NSString *)reconnectUrl{
    if(self.currentVideoUrl != nil &&
       self.ijkPlayer != nil &&
       reconnectUrl != nil &&
       [self.currentVideoUrl isEqualToString:reconnectUrl]){
        self.isReconnect = true;
        [self playVideoForReconnect:reconnectUrl];
    }
}

- (void)customizeVideoView:(CDVInvokedUrlCommand*)command{
    if(command.arguments == nil || command.arguments.count < 4){
        return;
    }
    double x = [command.arguments[0] doubleValue];
    double y = [command.arguments[1] doubleValue];
    double width = [command.arguments[2] doubleValue];
    double height = [command.arguments[3] doubleValue];
    
    self.videoViewX = x;
    self.videoViewY = y;
    self.videoViewWidth = width;
    self.videoViewHeight = height;
}

- (void)fullscreen:(CDVInvokedUrlCommand*)command{
    self.videoViewX = 0.0;
    self.videoViewY = 0.0;
    // self.videoViewWidth = [[UIScreen mainScreen] bounds].size.width;
    // self.videoViewHeight = [[UIScreen mainScreen] bounds].size.height;
    self.videoViewWidth = 1.0;
    self.videoViewHeight = 1.0;
}

- (UIView *) createVideoView{
    /**设置x,y,width,height为绝对大小和位置
    UIView *videoView = [[UIView alloc] initWithFrame:CGRectMake(self.videoViewX, self.videoViewY, self.videoViewWidth, self.videoViewHeight)];
    return videoView;
    */

    //设置的坐标和大小为屏幕长宽的百分比
    NSUInteger winWidth = [[UIScreen mainScreen] bounds].size.width;
    NSUInteger winHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat x = winWidth * self.videoViewX;
    CGFloat y = winHeight * self.videoViewY;
    CGFloat width = winWidth * self.videoViewWidth;
    CGFloat height = winHeight * self.videoViewHeight;
    UIView *videoView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    return videoView;
}


#pragma mark -
#pragma mark Life Cycle

/**
 * Registers obervers after plugin was initialized.
 */
- (void) pluginInitialize
{
    NSLog(@"pluginInitialize");
    [self fullscreen:NULL];
}

#pragma mark -
#pragma mark Helper


/**
 * Invokes the callback without any parameter.
 *
 * @return [ Void ]
 */
- (void) execCallback:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:result
                                callbackId:command.callbackId];
}

/**
 * Invokes the callback with a single boolean parameter.
 *
 * @return [ Void ]
 */
- (void) execCallback:(CDVInvokedUrlCommand*)command arg:(BOOL)arg
{
    CDVPluginResult *result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsBool:arg];

    [self.commandDelegate sendPluginResult:result
                                callbackId:command.callbackId];
}


- (IJKFFOptions *)optionsByDefault
{
    IJKFFOptions *options = [[IJKFFOptions alloc] init];
    
    [options setPlayerOptionIntValue:30     forKey:@"max-fps"];
    [options setPlayerOptionIntValue:5      forKey:@"framedrop"];
    [options setPlayerOptionIntValue:3      forKey:@"video-pictq-size"];
    [options setPlayerOptionIntValue:0      forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:960    forKey:@"videotoolbox-max-frame-width"];
    //[options setPlayerOptionIntValue:1                  forKey:@"reconnect"];
    
    [options setFormatOptionIntValue:0                  forKey:@"auto_convert"];
    
    [options setFormatOptionIntValue:30 * 1000 * 1000   forKey:@"timeout"];
    [options setFormatOptionValue:@"ijkplayer"          forKey:@"user-agent"];
    
    [options setFormatOptionIntValue:0L        forKey:@"packet-buffering"];
    [options setFormatOptionIntValue:100L      forKey:@"analyzemaxduration"];
    [options setFormatOptionIntValue:10240L      forKey:@"probesize"];
    [options setFormatOptionIntValue:1L      forKey:@"flush_packets"];
    
    [options setPlayerOptionIntValue:0L        forKey:@"packet-buffering"];
    [options setCodecOptionIntValue:0L   forKey:@"skip_loop_filter"];
    [options setPlayerOptionIntValue:1    forKey:@"analyzeduration"];
    [options setPlayerOptionIntValue:100    forKey:@"max-buffer-size"];
    
    options.showHudView   = NO;
    
    return options;
}

#pragma Selector func

- (void)startRender:(NSNotification*)notification {
    NSLog(@"startRender\n");
    if(self.isReconnect){
        if(self.ijkPlayer != nil && self.reconnectVideoUrl == self.currentVideoUrl){
            self.isReconnect = false;
            UIWindow * window = [[UIApplication sharedApplication] keyWindow];
            UIView *rootView = [[window subviews] objectAtIndex:0];
            [rootView exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
            
            [self removeMovieNotificationObservers:self.ijkPlayer];
            [self.ijkPlayer shutdown];
            self.ijkPlayer = nil;
            [self.playerRootView removeFromSuperview];
            self.playerRootView = nil;
            
            self.playerRootView = self.playerRootViewReconnect;
            self.ijkPlayer = self.ijkPlayerReconnect;
            self.currentVideoUrl = self.reconnectVideoUrl;
            
            self.playerRootViewReconnect = nil;
            self.ijkPlayerReconnect = nil;
            self.reconnectVideoUrl = nil;
        }else{
            [self stopReconnect];
        }
        
    }else{
        if(self.cdvInvokedUrlCommand){
            [self execCallback:self.cdvInvokedUrlCommand];
        }
    }
}

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKFFMoviePlayerController * player = notification.object;
    IJKMPMovieLoadState loadState = player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            if(self.currentVideoUrl != nil && self.ijkPlayer != nil){
                [self performSelector:@selector(reconnectVideo:) withObject:self.currentVideoUrl afterDelay:2];
            }

            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            if(self.currentVideoUrl != nil && self.ijkPlayer != nil){
                [self performSelector:@selector(reconnectVideo:) withObject:self.currentVideoUrl afterDelay:2];
            }
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    NSLog(@"mediaIsPrepareToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    switch (ijkPlayer.playbackState) {
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)ijkPlayer.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)ijkPlayer.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)ijkPlayer.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)ijkPlayer.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)ijkPlayer.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)ijkPlayer.playbackState);
            break;
        }
    }
}

#pragma Install Notifiacation

- (void)installMovieNotificationObservers:(IJKFFMoviePlayerController *) object {
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startRender:)
                                                 name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification
                                               object:object];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:object];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:object];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:object];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:object];
    
}

- (void)removeMovieNotificationObservers:(IJKFFMoviePlayerController *) object {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification
                                                  object:object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:object];
    
}

#pragma Install delegate

- (void)willOpenUrl:(IJKMediaUrlOpenData*) urlOpenData{
    NSLog(@"willOpenUrl\n");
}

- (int)invoke:(IJKMediaEvent)event attributes:(NSDictionary *)attributes{
    
    return 1;
}



@end

// codebeat:enable[TOO_MANY_FUNCTIONS]
