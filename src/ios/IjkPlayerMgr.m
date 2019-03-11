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
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface IjkPlayerMgr ()

@property (nonatomic, retain) UIView *playerRootView;
@property (nonatomic, retain) IJKFFMoviePlayerController *ijkPlayer;
@property (nonatomic, retain) CDVInvokedUrlCommand *cdvInvokedUrlCommand;

- (IJKFFOptions *)optionsByDefault;

@end

@implementation IjkPlayerMgr

@synthesize playerRootView, ijkPlayer, cdvInvokedUrlCommand;

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
    
    if(self.ijkPlayer != nil){
        [self.ijkPlayer stop];
        self.ijkPlayer = nil;
        [self.playerRootView removeFromSuperview];
        self.playerRootView = nil;
    }
    self.cdvInvokedUrlCommand = command;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    UIView *rootView = [[window subviews] objectAtIndex:0];
    self.playerRootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rootView.bounds.size.width, rootView.bounds.size.height)];
    self.playerRootView.backgroundColor = [UIColor blackColor];
    
    self.ijkPlayer = [[IJKFFMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString: videoUrl]
                                                                withOptions:[self optionsByDefault]];
    [self.ijkPlayer setScalingMode:IJKMPMovieScalingModeAspectFill];
    UIView *ijkView = [self.ijkPlayer view];
    ijkView.frame = self.playerRootView.bounds;
    ijkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.playerRootView addSubview:ijkView];
    [rootView insertSubview:self.playerRootView atIndex:1];
    [self installMovieNotificationObservers];
    [self.ijkPlayer prepareToPlay];
}

- (void) removeVideo:(CDVInvokedUrlCommand*)command{
    if(self.ijkPlayer != nil){
        [self.ijkPlayer stop];
        self.ijkPlayer = nil;
        [self.playerRootView removeFromSuperview];
        self.playerRootView = nil;
        self.cdvInvokedUrlCommand = nil;
    }
}

- (void) disconnectVideo:(CDVInvokedUrlCommand*)command{
    if(self.ijkPlayer != nil){
        [self.ijkPlayer stop];
        self.ijkPlayer = nil;
        [self.playerRootView removeFromSuperview];
        self.playerRootView = nil;
        self.cdvInvokedUrlCommand = nil;
    }
}

#pragma mark -
#pragma mark Life Cycle

/**
 * Registers obervers after plugin was initialized.
 */
- (void) pluginInitialize
{
    NSLog(@"pluginInitialize");
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
    [options setPlayerOptionIntValue:1L      forKey:@"framedrop"];
    [options setPlayerOptionIntValue:3      forKey:@"video-pictq-size"];
    [options setPlayerOptionIntValue:0      forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:960    forKey:@"videotoolbox-max-frame-width"];
    
    [options setFormatOptionIntValue:0                  forKey:@"auto_convert"];
    [options setFormatOptionIntValue:1                  forKey:@"reconnect"];
    [options setFormatOptionIntValue:30 * 1000 * 1000   forKey:@"timeout"];
    [options setFormatOptionValue:@"ijkplayer"          forKey:@"user-agent"];
    
    [options setFormatOptionIntValue:0L        forKey:@"packet-buffering"];
    [options setFormatOptionIntValue:100L      forKey:@"analyzemaxduration"];
    [options setFormatOptionIntValue:10240L      forKey:@"probesize"];
    [options setFormatOptionIntValue:1L      forKey:@"flush_packets"];
    
    options.showHudView   = NO;
    
    return options;
}

#pragma Selector func

- (void)startRender:(NSNotification*)notification {
    NSLog(@"startRender\n");
    if(self.cdvInvokedUrlCommand){
        [self execCallback:self.cdvInvokedUrlCommand];
    }
}

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = ijkPlayer.loadState;
    
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
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
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

- (void)installMovieNotificationObservers {
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startRender:)
                                                 name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification
                                               object:ijkPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:ijkPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:ijkPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:ijkPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:ijkPlayer];
    
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification
                                                  object:ijkPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:ijkPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:ijkPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:ijkPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:ijkPlayer];
    
}


@end

// codebeat:enable[TOO_MANY_FUNCTIONS]
