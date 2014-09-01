#include "RenderPluginDelegate.h"

extern "C" typedef void (*ScreenshotComplete)();

@interface ScreenshotCreator : RenderPluginDelegate
{
    NSString*               screenshotPath;
    ScreenshotComplete      callback;

    BOOL                    requestedScreenshot;
    BOOL                    creatingScreenshot;
}
- (id)init;

- (void)onBeforeMainDisplaySurfaceRecreate:(struct RenderingSurfaceParams*)params;
- (void)onFrameResolved;

- (void)queryScreenshot:(NSString*)path callback:(ScreenshotComplete)callback;

@end
