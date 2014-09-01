
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

#include <stdlib.h>
#include <stdint.h>


extern "C" void* GLESTexture_CreateTexture(const char* image_filename, int* w, int* h)
{
    NSString* imageName = [NSString stringWithUTF8String:image_filename];
    NSString* imagePath = [[[[NSBundle mainBundle] pathForResource: imageName ofType: @"png"] retain] autorelease];

    UIImage* sourceImage = [[UIImage imageWithContentsOfFile: imagePath] retain];

    CGImageRef imageData = sourceImage.CGImage;
    unsigned   imageW    = CGImageGetWidth(imageData);
    unsigned   imageH    = CGImageGetHeight(imageData);

    GLubyte* textureData = (GLubyte*)::malloc(imageW*imageH * 4);
    ::memset(textureData, 0x00, imageW*imageH * 4);

    CGContextRef textureContext = CGBitmapContextCreate( textureData, imageW, imageH, 8, imageW * 4,
    CGImageGetColorSpace(imageData), kCGImageAlphaPremultipliedLast
    );
    CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
    CGContextDrawImage(textureContext, CGRectMake(0,0, imageW, imageH), imageData);
    CGContextRelease(textureContext);

    GLuint texture = 0;
    glGenTextures(1, &texture);

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageW, imageH, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);

    ::free(textureData);
    [sourceImage release];

    *w = (int)imageW;
    *h = (int)imageH;

    return (void*)(intptr_t)texture;
}
