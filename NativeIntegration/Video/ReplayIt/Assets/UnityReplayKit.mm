#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>
#import "UnityReplayKit.h"
#include "UnityForwardDecls.h"


static UnityReplayKit* _replayKit;


@implementation UnityReplayKit
{
	NSString* _lastError;
	RPPreviewViewController* _previewController;
}

+ (UnityReplayKit*)Instance
{
	if (_replayKit == nil)
    {
		_replayKit = [[UnityReplayKit alloc] init];
    }
	return _replayKit;
}

- (BOOL)screenRecordingAvailable
{
	return _previewController != nil;
}

- (NSString *)getLastError
{
    return _lastError;
}


- (RPPreviewViewController*)getPreviewController
{
    return _previewController;
}

- (BOOL)startRecoring:(BOOL)enableMicrophone
{
	RPScreenRecorder* recorder = [RPScreenRecorder sharedRecorder];
	if (recorder == nil)
	{
		_lastError = [NSString stringWithUTF8String:"Failed to get Screen Recorder"];
		return NO;
	}
    
	[recorder setDelegate:self];
	[recorder startRecordingWithMicrophoneEnabled:enableMicrophone handler:^(NSError* error){
		if (error != nil)
        {
			_lastError = [error description];
        }
	}];
	
	return YES;
}

- (BOOL)recording
{
	RPScreenRecorder* recorder = [RPScreenRecorder sharedRecorder];
	if (recorder == nil)
	{
		_lastError = [NSString stringWithUTF8String:"Failed to get Screen Recorder"];
		return NO;
	}
	return [recorder isRecording];
}

- (BOOL)stopRecording
{
	RPScreenRecorder* recorder = [RPScreenRecorder sharedRecorder];
	if (recorder == nil)
	{
		_lastError = [NSString stringWithUTF8String:"Failed to get Screen Recorder"];
		return NO;
	}
    
	[recorder stopRecordingWithHandler:^(RPPreviewViewController* previewViewController, NSError* error){
		if (error != nil)
		{
			_lastError = [error description];
			return;
		}
		if (previewViewController != nil)
		{
			[previewViewController setPreviewControllerDelegate:self];
			_previewController = previewViewController;
		}
	}];
	
	return YES;
}

- (void)screenRecorder:(nonnull RPScreenRecorder*)screenRecorder didStopRecordingWithError:(nonnull NSError*)error previewViewController:(nullable RPPreviewViewController*)previewViewController
{
    if (error != nil)
    {
		_lastError = [error description];
    }
	_previewController = previewViewController;
}

- (BOOL)preview
{
	if (_previewController == nil)
	{
		_lastError = [NSString stringWithUTF8String:"No recording available"];
		return NO;
	}
	
	[_previewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [[[UnityGetGLView() window] rootViewController] presentViewController:_previewController animated:YES completion:^()
    {
        _previewController = nil;
    }];
	return YES;
}

- (BOOL)discard
{
	if (_previewController == nil)
    {
		return YES;
    }
    
	RPScreenRecorder* recorder = [RPScreenRecorder sharedRecorder];
	if (recorder == nil)
	{
		_lastError = [NSString stringWithUTF8String:"Failed to get Screen Recorder"];
		return NO;
	}
    
	[recorder discardRecordingWithHandler:^()
    {
        _previewController = nil;
    }];
    // TODO - the above callback doesn't seem to be working at the moment.
    _previewController = nil;
	
    return YES;
}

- (void)previewControllerDidFinish:(RPPreviewViewController*)previewController
{
	if (previewController != nil)
    {
		[previewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end


extern "C"
{
	
int UnityReplayKitRecordingAvailable()
{
	if (_replayKit == nil)
		return 0;
	return [[UnityReplayKit Instance] screenRecordingAvailable] == YES;
}
	
const char* UnityReplayKitLastError()
{
	if (_replayKit == nil)
    {
		return NULL;
    }
    
	NSString* err = [[UnityReplayKit Instance] getLastError];
	if (err == nil)
    {
		return NULL;
    }
	const char* error = [err cStringUsingEncoding:NSUTF8StringEncoding];
	if (error != NULL)
    {
		error = strdup(error);
    }
	return error;
}

int UnityReplayKitStartRecording(int enableMicrophone)
{
	bool enableMic = enableMicrophone ? YES : NO;
	return [[UnityReplayKit Instance] startRecoring:enableMic] == YES;
}

int UnityReplayKitIsRecording()
{
	if (_replayKit == nil)
    {
		return -1;
    }
	return [[UnityReplayKit Instance] recording] == YES;
}
	
int UnityReplayKitStopRecording()
{
	if (_replayKit == nil)
    {
		return -1;
    }
	return [[UnityReplayKit Instance] stopRecording] == YES;
}

int UnityReplayKitDiscard()
{
	if (_replayKit == nil)
    {
		return -1;
    }
	[[UnityReplayKit Instance] discard];
	return 1;
}
	
int UnityReplayKitPreview()
{
	if (_replayKit == nil)
    {
		return -1;
    }
	return [[UnityReplayKit Instance] preview] == YES;
}

}
