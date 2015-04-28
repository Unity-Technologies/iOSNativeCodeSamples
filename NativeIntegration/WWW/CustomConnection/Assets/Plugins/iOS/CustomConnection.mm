#include "Unity/WWWConnection.h"

@interface UnityWWWCustomRequestProvider : UnityWWWRequestDefaultProvider
{
}
+ (NSMutableURLRequest*)allocRequestForHTTPMethod:(NSString*)method url:(NSURL*)url headers:(NSDictionary*)headers;
@end

@implementation UnityWWWCustomRequestProvider
+ (NSMutableURLRequest*)allocRequestForHTTPMethod:(NSString*)method url:(NSURL*)url headers:(NSDictionary*)headers
{
    NSMutableURLRequest* request = [super allocRequestForHTTPMethod: method url: url headers: headers];

    // let's pretend for security reasons we dont want ANY cache nor cookies
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setHTTPShouldHandleCookies: NO];

    // let's pretend we want special secret info in header
    [request setValue: @"123456789"forHTTPHeaderField: @"Secret"];

    return request;
}

@end

@interface UnityWWWCustomConnectionDelegate : UnityWWWConnectionDelegate
{
}
@end

@implementation UnityWWWCustomConnectionDelegate
- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // we dont want caching
    return nil;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    // let's just print something here for test
    [super connection: connection didReceiveResponse: response];
    if ([response isMemberOfClass: [NSHTTPURLResponse class]])
        ::printf_console("We've got response with status: %d\n", [(NSHTTPURLResponse*)response statusCode]);
}

@end

IMPL_WWW_DELEGATE_SUBCLASS(UnityWWWCustomConnectionDelegate);
IMPL_WWW_REQUEST_PROVIDER(UnityWWWCustomRequestProvider);
