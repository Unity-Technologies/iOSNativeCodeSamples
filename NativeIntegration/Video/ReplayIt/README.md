# ReplayKit Plugin


## Description

This sample shows how one can create a native plugin in order to Utilize ReplayKit on iOS.

##Prerequisites

Unity: 5.2

iOS: 9.0 or later

## How does it work

Native hooks are exposed that allow the Unity runtime to initiate native calls, and respond to callbacks within the ReplayKit framework.  

## Notes

There is one ReplayKit callback that doesn't seem to be working in `UnityReplayKit.mm` 
```
	[recorder discardRecordingWithHandler:^()
    {
        _previewController = nil;
    }];
    // TODO - the above callback doesn't seem to be working at the moment.
    _previewController = nil;
```