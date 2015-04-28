#include "Unity/VideoPlayer.h"

#if UNITY_VERSION < 450
    #include "iPhone_View.h"
#endif

#import <UIKit/UIKit.h>

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

extern "C" __attribute__((visibility("default"))) NSString * const kUnityViewDidRotate;

@interface VideoPlayerScripting : NSObject<VideoPlayerDelegate>
{
    @public
    VideoPlayer*        player;
    VideoPlayerView*    view;
}
- (void)playVideo:(NSURL*)url;
- (void)orientationDidChange:(NSNotification *)notification;

- (void)onPlayerReady;
- (void)onPlayerDidFinishPlayingVideo;
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

- (void)orientationDidChange:(NSNotification *)notification
{
    CGRect bounds = UnityGetGLView().bounds;
    view.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
}

- (void)onPlayerReady
{
    CGRect bounds = UnityGetGLView().bounds;

    if (!view)
    {
        view = [[VideoPlayerView alloc] initWithFrame: bounds];
        view.bounds = CGRectMake(0, 0, [player videoSize].width, [player videoSize].height);
        view.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);

        [UnityGetGLView() addSubview: view];
    }

    view.hidden = NO;

    [player playToView: view];
    [player setAudioVolume: 1.0f];
}

- (void)onPlayerDidFinishPlayingVideo
{
    view.hidden = YES;
}

@end

static VideoPlayerScripting* player = nil;

extern "C" void VideoPlayer_PlayVideo(const char* filename)
{
    if (!player)
    {
        player = [[VideoPlayerScripting alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver: player selector: @selector(orientationDidChange:) name: kUnityViewDidRotate object: nil];
    }

    NSURL* url = nil;
    if (::strstr(filename, "://"))
        url = [NSURL URLWithString: [NSString stringWithUTF8String: filename]];
    else
        url = [NSURL fileURLWithPath: [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: [NSString stringWithUTF8String: filename]]];

    [player playVideo: url];
}

extern "C" void VideoPlayer_PauseVideo()
{
    [player->player pause];
}

extern "C" void VideoPlayer_ResumeVideo()
{
    [player->player resume];
}

extern "C" void VideoPlayer_RewindVideo()
{
    [player->player rewind];
}
