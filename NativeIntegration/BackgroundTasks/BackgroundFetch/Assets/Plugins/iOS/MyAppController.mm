#import <UIKit/UIKit.h>
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURL.h>

#import "UnityAppController.h"

extern bool         _unityAppReady;

static NSString*    _FetchedText;


@interface MyAppController : UnityAppController
{
}
- (void)application:(UIApplication*)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions;
@end

@implementation MyAppController
- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [application setMinimumBackgroundFetchInterval: UIApplicationBackgroundFetchIntervalMinimum];
    return [super application: application willFinishLaunchingWithOptions: launchOptions];
}

- (void)application:(UIApplication*)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSURL*          url     = [NSURL URLWithString: @"http://unity3d.com"];
    NSURLRequest*   request = [NSURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 10.0];
    NSData*         data    = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString*       text    = [NSString stringWithUTF8String: (const char*)data.bytes];

    // i dont think this is appropriate place to fully write all the words i can say about web 2.0 obsession
    // so we just grab <title> and be gone
    NSRange     titleStartRange    = [text rangeOfString: @"<title>"];
    unsigned    titleStart         = titleStartRange.location + titleStartRange.length;
    NSRange     titleEndRange      = [text rangeOfString: @"<" options: 0 range: NSMakeRange(titleStart, text.length - titleStart)];

    _FetchedText = [text substringWithRange: NSMakeRange(titleStart, titleEndRange.location - titleStart)];

    // do not try to run player loop before unity is inited
    if (_unityAppReady)
        UnityBatchPlayerLoop();

    completionHandler(UIBackgroundFetchResultNewData);
}

@end

extern "C" const char* QueryFetchedText()
{
    if (_FetchedText == nil)
        return 0;

    char* ret = (char*)::malloc(_FetchedText.length + 1);
    ::memcpy(ret, [_FetchedText UTF8String], _FetchedText.length);
    ret[_FetchedText.length] = 0;

    return ret;
}


IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)
