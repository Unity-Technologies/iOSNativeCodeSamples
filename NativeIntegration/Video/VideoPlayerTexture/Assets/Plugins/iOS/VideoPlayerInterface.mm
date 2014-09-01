#include "Unity/VideoPlayer.h"

#if UNITY_VERSION < 450
    #include "iPhone_View.h"
#endif

#import <UIKit/UIKit.h>

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

@interface VideoPlayerScripting : NSObject <VideoPlayerDelegate>
{
    @public VideoPlayer* player;
    @public BOOL         playerReady;
}
- (void)playVideo:(NSURL*)url;

- (void)onPlayerReady;
- (void)onPlayerDidFinishPlayingVideo;
@end

@implementation VideoPlayerScripting
- (void)playVideo:(NSURL*)url
{
    if(!player)
    {
        player = [[VideoPlayer alloc] init];
        player.delegate = self;
    }
    [player loadVideo:url];
}

- (void)onPlayerReady
{
    playerReady = YES;

    [player playToTexture];
    [player setAudioVolume:1.0f];
}

- (void)onPlayerDidFinishPlayingVideo
{
    playerReady = NO;
}
@end

static VideoPlayerScripting* _GetPlayer()
{
    static VideoPlayerScripting* _Player = nil;
    if(!_Player)
        _Player = [[VideoPlayerScripting alloc] init];

    return _Player;
}
static NSURL* _GetUrl(const char* filename)
{
    NSURL* url = nil;
    if(::strstr(filename, "://"))
        url = [NSURL URLWithString: [NSString stringWithUTF8String:filename]];
    else
        url = [NSURL fileURLWithPath: [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: [NSString stringWithUTF8String:filename]]];

    return url;
}


extern "C" bool VideoPlayer_CanOutputToTexture(const char* filename)
{
    return [VideoPlayer CanPlayToTexture:_GetUrl(filename)];
}

extern "C" bool VideoPlayer_PlayerReady()
{
    return [_GetPlayer()->player readyToPlay];
}

extern "C" float VideoPlayer_DurationSeconds()
{
    return [_GetPlayer()->player durationSeconds];
}

extern "C" void VideoPlayer_VideoExtents(int* w, int* h)
{
    CGSize sz = [_GetPlayer()->player videoSize];
    *w = (int)sz.width;
    *h = (int)sz.height;
}

extern "C" int VideoPlayer_CurFrameTexture()
{
    return [_GetPlayer()->player curFrameTexture];
}

extern "C" void VideoPlayer_PlayVideo(const char* filename)
{
    [_GetPlayer() playVideo:_GetUrl(filename)];
}
