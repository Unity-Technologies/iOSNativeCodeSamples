#import <UIKit/UIKit.h>
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURL.h>

#import "UnityAppController.h"

extern bool         _unityAppReady;

static NSString*    _FetchedText;


@interface MyAppController : UnityAppController
{
}
-(void)application:(UIApplication*)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
-(BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions;
@end

@implementation MyAppController
-(BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return [super application:application willFinishLaunchingWithOptions:launchOptions];
}
-(void)application:(UIApplication*)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSURL*          url     = [NSURL URLWithString:@"http://unity3d.com/legal/eula"];
    NSURLRequest*   request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSData*         data    = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString*       text    = [NSString stringWithUTF8String:(const char*)data.bytes];

    // the page will contain "Last updated: [date]" inside some tag
    NSRange     updateStartRange    = [text rangeOfString:@">Last updated:"];
    unsigned    updateStart         = updateStartRange.location + updateStartRange.length + 1;
    NSRange     updateEndRange      = [text rangeOfString:@"<" options:0 range:NSMakeRange(updateStart, text.length - updateStart)];

    _FetchedText = [text substringWithRange:NSMakeRange(updateStart, updateEndRange.location - updateStart)];

    // do not try to run player loop before unity is inited
    if(_unityAppReady)
        UnityBatchPlayerLoop();

    completionHandler(UIBackgroundFetchResultNewData);
}
@end

extern "C" const char* QueryFetchedText()
{
    if(_FetchedText == nil)
        return 0;

    char* ret = (char*)::malloc(_FetchedText.length+1);
    ::memcpy(ret, [_FetchedText UTF8String], _FetchedText.length);
    ret[_FetchedText.length] = 0;

    return ret;
}


IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)
