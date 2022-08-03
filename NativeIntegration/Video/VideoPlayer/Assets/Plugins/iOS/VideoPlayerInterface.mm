#if UNITY_VERSION < 500
    #error this sample was upgraded to be compatible only with 5.x
#endif

#include "Unity/VideoPlayer.h"
#include "UnityAppController.h"
#import <UIKit/UIKit.h>

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

@interface MyVideoPlayerView : VideoPlayerView
{
}
- (void)onUnityUpdateViewLayout;
@end
@implementation MyVideoPlayerView
- (void)onUnityUpdateViewLayout
{
    self.center = GetAppController().rootView.center;
}
@end

@interface VideoPlayerScripting : NSObject<VideoPlayerDelegate>
{
    VideoPlayer*        player;
    VideoPlayerView*    view;
}
- (void)playVideo:(NSURL*)url;

- (void)onPlayerReady;
- (void)onPlayerDidFinishPlayingVideo;

- (void)pause;
- (void)resume;
- (void)rewind;
@end

@implementation VideoPlayerScripting
- (void)playVideo:(NSURL*)url
{
    if (!player)
    {
        player = [[VideoPlayer alloc] init];
        player.delegate = self;
    }
    [player loadVideo: url];
}

- (void)onPlayerReady
{
    if (!view)
    {
        CGSize videoExt     = [player videoSize];
        CGRect videoFrame   = CGRectMake(0, 0, videoExt.width, videoExt.height);
        view = [[MyVideoPlayerView alloc] initWithFrame:videoFrame];

        [GetAppController().rootView addSubview:view];
        [GetAppController().rootView layoutSubviews];
    }

    view.hidden = NO;

    [player playToView: view];
    [player setAudioVolume: 1.0f];
}
- (void)onPlayerDidFinishPlayingVideo
{
    view.hidden = YES;
}
- (void)onPlayerError:(NSError*)error
{
}

- (void)pause   { [player pause]; }
- (void)resume  { [player resume]; }
- (void)rewind  { [player rewind]; }

@end

static VideoPlayerScripting* _Player = nil;

extern "C" void VideoPlayer_PlayVideo(const char* filename)
{
    if (!_Player)
        _Player = [[VideoPlayerScripting alloc] init];

    NSURL* url = nil;
    if (::strstr(filename, "://"))
        url = [NSURL URLWithString:[NSString stringWithUTF8String:filename]];
    else
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]]];

    [_Player playVideo:url];
}

extern "C" void VideoPlayer_PauseVideo()    { [_Player pause]; }
extern "C" void VideoPlayer_ResumeVideo()   { [_Player resume]; }
extern "C" void VideoPlayer_RewindVideo()   { [_Player rewind]; }
