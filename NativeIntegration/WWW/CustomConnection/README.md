# Tweaking the connection used in Unity WWW class.


## Description

This sample shows how to tweak WWW connection to better suit your needs.


##Prerequisites

Unity: 4.3.1 - 2019.1

iOS: any


## How does it work

The place of interest is Plugins/iOS/CustomConnection.mm

First, we subclass UnityWWWRequestDefaultProvider to tweak the NSURLRequest object used for connection. We could implement UnityWWWRequestProvider protocol, but we want to reuse base code.

	@interface UnityWWWCustomRequestProvider : UnityWWWRequestDefaultProvider
	{
	}
	+ (NSMutableURLRequest*)allocRequestForHTTPMethod:(NSString*)method url:(NSURL*)url headers:(NSDictionary*)headers;
	@end

	@implementation UnityWWWCustomRequestProvider
	+ (NSMutableURLRequest*)allocRequestForHTTPMethod:(NSString*)method url:(NSURL*)url headers:(NSDictionary*)headers
	{
		NSMutableURLRequest* request = [super allocRequestForHTTPMethod:method url:url headers:headers];

We sill disable any data caching by iOS:

	request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	[request setHTTPShouldHandleCookies:NO];

And pretend we need some secret header that will be checked by our server:

	[request setValue:@"123456789"forHTTPHeaderField:@"Secret"];

And then we "register" our subclass for unity to use when creating NSURLRequest:

	IMPL_WWW_REQUEST_PROVIDER(UnityWWWCustomRequestProvider);

Second, we subclass UnityWWWConnectionDelegate to have customized connection handling:

	@interface UnityWWWCustomConnectionDelegate : UnityWWWConnectionDelegate
	{
	}
	@end

	@implementation UnityWWWCustomConnectionDelegate

We disable data caching:

	- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
	{
		// we dont want caching
		return nil;
	}

And we hook up on receiving data. To not complicate code we just print to log. Please note that we call super method so unity actually gets data.

	- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
	{
		// let's just print something here for test
		[super connection:connection didReceiveResponse:response];
		if([response isMemberOfClass:[NSHTTPURLResponse class]])
			::printf_console("We've got response with status: %d\n", [(NSHTTPURLResponse*)response statusCode]);
	}

And then we "register" our subclass for unity to use when creating connection delegate:

	IMPL_WWW_REQUEST_PROVIDER(UnityWWWCustomRequestProvider);

That's it, in C# we simply use WWW class to download texture and it will use our implementation. You can easily check that by that log string we output in didReceiveResponse
