#import <UIKit/UIKit.h>
#include "UnityMetalSupport.h"

#include <stdlib.h>
#include <stdint.h>

static UIImage* LoadImage(const char* filename)
{
    NSString* imageName = [NSString stringWithUTF8String: filename];
    NSString* imagePath = [[NSBundle mainBundle] pathForResource: imageName ofType: @"png"];

    return [UIImage imageWithContentsOfFile: imagePath];
}

// you need to free this pointer
static void* LoadDataFromImage(UIImage* image)
{
    CGImageRef imageData    = image.CGImage;
    unsigned   imageW       = CGImageGetWidth(imageData);
    unsigned   imageH       = CGImageGetHeight(imageData);

    // for the sake of the sample we enforce 128x128 textures
    assert(imageW == 128 && imageH == 128);

    void* textureData = ::malloc(imageW * imageH * 4);
    ::memset(textureData, 0x00, imageW * imageH * 4);

    CGContextRef textureContext = CGBitmapContextCreate(textureData, imageW, imageH, 8, imageW * 4, CGImageGetColorSpace(imageData), kCGImageAlphaPremultipliedLast);
    CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
    CGContextDrawImage(textureContext, CGRectMake(0, 0, imageW, imageH), imageData);
    CGContextRelease(textureContext);

    return textureData;
}

static uintptr_t CreateMetalTexture(void* data, unsigned w, unsigned h)
{
#if UNITY_CAN_USE_METAL
    Class MTLTextureDescriptorClass = [UnityGetMetalBundle() classNamed: @"MTLTextureDescriptor"];

    MTLTextureDescriptor* texDesc =
        [MTLTextureDescriptorClass texture2DDescriptorWithPixelFormat: MTLPixelFormatRGBA8Unorm width: w height: h mipmapped: NO];

    id<MTLTexture> tex = [UnityGetMetalDevice() newTextureWithDescriptor: texDesc];

    MTLRegion r = MTLRegionMake3D(0, 0, 0, w, h, 1);
    [tex replaceRegion: r mipmapLevel: 0 withBytes: data bytesPerRow: w * 4];

    return (uintptr_t)(__bridge_retained void*)tex;
#else
    return 0;
#endif
}

static void DestroyMetalTexture(uintptr_t tex)
{
#if UNITY_CAN_USE_METAL
    id<MTLTexture> mtltex = (__bridge_transfer id<MTLTexture>)(void*) tex;
    mtltex = nil;
#endif
}

extern "C" intptr_t CreateNativeTexture(const char* filename)
{
    UIImage*    image       = LoadImage(filename);
    void*       textureData = LoadDataFromImage(image);

    uintptr_t ret = 0;
    if (UnitySelectedRenderingAPI() == apiMetal)
        ret = CreateMetalTexture(textureData, image.size.width, image.size.height);

    ::free(textureData);
    return ret;
}

extern "C" void DestroyNativeTexture(uintptr_t tex)
{
    if (UnitySelectedRenderingAPI() == apiMetal)
        DestroyMetalTexture(tex);
}
