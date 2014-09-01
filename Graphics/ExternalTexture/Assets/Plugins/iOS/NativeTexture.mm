
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

#include <stdlib.h>
#include <stdint.h>

static UIImage* LoadImage(const char* filename)
{
    NSString* imageName = [NSString stringWithUTF8String:filename];
    NSString* imagePath = [[[[NSBundle mainBundle] pathForResource: imageName ofType: @"png"] retain] autorelease];

    return [[UIImage imageWithContentsOfFile: imagePath] retain];
}

// you need to free this pointer
static void* LoadDataFromImage(UIImage* image)
{
    CGImageRef imageData    = image.CGImage;
    unsigned   imageW       = CGImageGetWidth(imageData);
    unsigned   imageH       = CGImageGetHeight(imageData);

    // for the sake of the sample we enforce 128x128 textures
    assert(imageW == 128 && imageH == 128);

    void* textureData = ::malloc(imageW*imageH * 4);
    ::memset(textureData, 0x00, imageW*imageH * 4);

    CGContextRef textureContext = CGBitmapContextCreate( textureData, imageW, imageH, 8, imageW * 4,
    CGImageGetColorSpace(imageData), kCGImageAlphaPremultipliedLast
    );
    CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
    CGContextDrawImage(textureContext, CGRectMake(0,0, imageW, imageH), imageData);
    CGContextRelease(textureContext);

    return textureData;
}

static uintptr_t CreateGlesTexture(void* data, unsigned w, unsigned h)
{
    GLuint texture = 0;
    glGenTextures(1, &texture);

    GLint curGLTex = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &curGLTex);

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

    glBindTexture(GL_TEXTURE_2D, curGLTex);

    return texture;
}


extern "C" intptr_t CreateNativeTexture(const char* filename)
{
    UIImage*    image       = LoadImage(filename);
    void*       textureData = LoadDataFromImage(image);

    uintptr_t ret = 0;
    ret = CreateGlesTexture(textureData, image.size.width, image.size.height);

    ::free(textureData);
    [image release];

    return ret;
}

extern "C" void DestroyNativeTexture(uintptr_t tex)
{
    GLint curGLTex = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &curGLTex);

    GLuint glTex = tex;
    glDeleteTextures(1, &glTex);

    glBindTexture(GL_TEXTURE_2D, curGLTex);
}
