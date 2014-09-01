#import "ScreenshotCreator.h"

#include "GlesHelper.h"
#include "DisplayManager.h"

static ScreenshotCreator* _Creator = nil;

@implementation ScreenshotCreator
{
    char*   imageBuffer;
    int     bufferSize;

    int     bufferW;
    int     bufferRowLen;
    int     bufferH;

    int     imageW;
    int     imageH;

    BOOL    bufferFlipped;
}

- (id)init
{
    NSAssert(_Creator == nil, @"You can have only one instance of ScreenshotCreator");
    if((self = [super init]))
    {
        self->screenshotPath = nil;
        self->callback = nil;

        self->requestedScreenshot = self->creatingScreenshot = NO;

        imageBuffer = 0;
        bufferSize = imageW = imageH = 0;
    }

    _Creator = self;
    return self;
}

- (void)onBeforeMainDisplaySurfaceRecreate:(struct RenderingSurfaceParams*)params
{
    params->useCVTextureCache = true;
}

- (void)onFrameResolved
{
    if(self->requestedScreenshot)
    {
        self->creatingScreenshot = YES;

        CVPixelBufferRef pixelBuf = (CVPixelBufferRef)mainDisplaySurface->cvPixelBuffer;

        bufferSize      = CVPixelBufferGetDataSize(pixelBuf);
        imageBuffer     = (char*)::malloc(bufferSize);
        bufferW         = CVPixelBufferGetWidth(pixelBuf);
        bufferH         = CVPixelBufferGetHeight(pixelBuf);
        bufferRowLen    = CVPixelBufferGetBytesPerRow(pixelBuf);
        bufferFlipped   = CVOpenGLESTextureIsFlipped((CVOpenGLESTextureRef)mainDisplaySurface->cvTextureCacheTexture);

        imageW  = mainDisplaySurface->targetW;
        imageH  = mainDisplaySurface->targetH;

        // we need to copy data to avoid stalling gl
        CVPixelBufferLockBaseAddress(pixelBuf, kCVPixelBufferLock_ReadOnly);
        {
            ::memcpy(imageBuffer, CVPixelBufferGetBaseAddress(pixelBuf), bufferSize);
        }
        CVPixelBufferUnlockBaseAddress(pixelBuf, kCVPixelBufferLock_ReadOnly);
        [self performSelectorInBackground:@selector(saveImage) withObject:NULL];
    }
    self->requestedScreenshot = NO;
}

- (void)queryScreenshot:(NSString*)path callback:(ScreenshotComplete)callback_
{
    if(!self->creatingScreenshot)
    {
        self->screenshotPath = [path retain];
        self->callback = callback_;
        self->requestedScreenshot = YES;
    }
}

- (void)saveImage
{
    // we need to convert bgra->rgba and possibly flip image upside-down
    // bgra->rgba can be done with Accelerate.framework vImagePermuteChannels_ARGB8888
    // also manual flipping could be avoided if we used pnglib directly (write png rows right away)
    // anyway we strive for min deps here ;-)

    char* finalImageData = (char*)::malloc(4*imageW*imageH);
    {
        const int srcRowSize = bufferRowLen;
        const int dstRowSize = 4*imageW;
        const int srcRowNext = bufferFlipped ? -srcRowSize : srcRowSize;

        char* srcRow = imageBuffer;
        char* dstRow = finalImageData;

        if(bufferFlipped)   srcRow = imageBuffer + (bufferH-1) * srcRowSize;
        else                srcRow = imageBuffer;

        for(int i = 0 ; i < imageH ; ++i, srcRow += srcRowNext, dstRow += dstRowSize)
        {
            for(int j = 0 ; j < imageW ; ++j)
            {
                dstRow[4*j+0] = srcRow[4*j+2];
                dstRow[4*j+1] = srcRow[4*j+1];
                dstRow[4*j+2] = srcRow[4*j+0];
                dstRow[4*j+3] = srcRow[4*j+3];
            }
        }
    }
    ::free(imageBuffer);

    CGDataProviderRef cgProvider = CGDataProviderCreateWithData(0, finalImageData, 4*imageW*imageH, 0);
    CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage =
        CGImageCreate(  imageW, imageH, 8, 32, 4*imageW,
                        cgColorSpace, kCGBitmapByteOrderDefault, cgProvider, 0, NO, kCGRenderingIntentDefault
    );
    CGDataProviderRelease(cgProvider);
    CGColorSpaceRelease(cgColorSpace);

    UIImage* image = [[UIImage imageWithCGImage:cgImage] retain];
    CGImageRelease(cgImage);

    NSURL* documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject retain];
    NSURL* fileUrl   = [[documents URLByAppendingPathComponent:screenshotPath] retain];

    NSData* pngData = UIImagePNGRepresentation(image);
    [pngData writeToURL:fileUrl atomically:YES];
    [image release];

    [documents release];
    [fileUrl release];

    ::free(finalImageData);

    [screenshotPath release];
    [self performSelectorOnMainThread: @selector(doneSavingImage) withObject:NULL waitUntilDone:NO];
}

- (void)doneSavingImage
{
    self->creatingScreenshot = NO;
    self->callback();
}

@end


extern "C" void CaptureScreenshot(ScreenshotComplete complete, const char* filename)
{
    [_Creator queryScreenshot:[NSString stringWithUTF8String:filename] callback:complete];
}
