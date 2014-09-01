#import <UIKit/UIKit.h>
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURL.h>

#import "UnityAppController.h"

extern bool			_unityAppReady;

static NSString*	_UnityVersion;


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
    NSURL*          url     = [NSURL URLWithString:@"http://unity3d.com/unity/download"];
    NSURLRequest*   request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSData*         data    = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString*       text    = [NSString stringWithUTF8String:(const char*)data.bytes];

    // the page will contain
    // <input type="hidden" name="version" value="X.X.X" />
    // along download button
    // also we consider that we have only single digits in there (regex will do but that's overkill)
    NSRange     verStartRange   = [text rangeOfString:@"<input type=\"hidden\" name=\"version\" value=\""];
    unsigned    verStart        = verStartRange.location + verStartRange.length;

    NSRange verRange = {verStart, 5};
    _UnityVersion = [text substringWithRange:verRange];

    // do not try to run player loop before unity is inited
    if(_unityAppReady)
        UnityBatchPlayerLoop();

    completionHandler(UIBackgroundFetchResultNewData);
}
@end

extern "C" const char* QueryUnityVersion()
{
    if(_UnityVersion == nil)
        return 0;

    char* ret = (char*)::malloc(_UnityVersion.length+1);
    ::memcpy(ret, [_UnityVersion UTF8String], _UnityVersion.length);
    ret[_UnityVersion.length] = 0;

    return ret;
}


IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)
