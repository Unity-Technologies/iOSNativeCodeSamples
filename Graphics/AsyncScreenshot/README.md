# Using RenderPlugin API


## Description

This is a sample of usage of native **RenderPluginDelegate**. It will make screenshots asynchronously on demand.


##Prerequisites

Unity: 4.3

iOS: any


## How does it work

In Plugins/iOS folder you can see our UnityAppController subclass (MyAppController.mm) and render plugin implementation (ScreenshotCreator.mm)

MyAppController.mm contains shouldAttachRenderDelegate method override, to register our render plugin:

	- (void)shouldAttachRenderDelegate;
	{
		self.renderDelegate = [[ScreenshotCreator alloc] init];
	}


ScreenshotCreator.mm demonstrates basic steps needed to implement your own plugin.

First, on registering we tweak Unity's Rendering Surface to back backbuffer with CVTextureCache

	- (void)onBeforeMainDisplaySurfaceRecreate:(struct RenderingSurfaceParams*)params
	{
		params->useCVTextureCache = true;
	}


Second, we hook up on the unity rendering at the moment frame was fully rendered. That will be called right before blitting to screen (if resolution is not native) and presenting frame:

	- (void)onFrameResolved

Please note, how we use the fact that backbuffer is backed by CVTextureCache:

	CVPixelBufferRef pixelBuf = (CVPixelBufferRef)mainDisplaySurface->cvPixelBuffer;

	...

	// we need to copy data to avoid stalling gl
	CVPixelBufferLockBaseAddress(pixelBuf, kCVPixelBufferLock_ReadOnly);
	{
		::memcpy(imageBuffer, CVPixelBufferGetBaseAddress(pixelBuf), bufferSize);
	}
	CVPixelBufferUnlockBaseAddress(pixelBuf, kCVPixelBufferLock_ReadOnly);

And after we copied the contents of the screen we start saving it to image on the background thread:

	[self performSelectorInBackground:@selector(saveImage) withObject:NULL];


All other code is very basic saving image to file and some glue to command the plugin from C#.
