# Creating Unity Texture from GLES Texture


## Description

This is a sample of usage of **Texture2D.CreateExternalTexture** and **Texture2D.UpdateExternalTexture**. It will load png into metal texture in native plugin and give it back to Unity to be used like normal Unity Texture.


##Prerequisites

Unity: 2022

iOS: iOS 13+


## How does it work

There are two pieces of interest: TestNativeTexture.cs and Plugins/iOS/NativeTexture.mm.

In Plugins/iOS folder you can see three files: NativeTexture.mm (native plugin) and images that we will use. All the will be copied to your project, so we can load png from App Bundle.

NativeTexture.mm contains just two functions: one for creating texture and the other one for destroying it. The only interesting place is texture creation

	extern "C" void* GLESTexture_CreateTexture(const char* image_filename, int* w, int* h)

It will load png image from App Bundle to UIImage and pass this data to Metal:

	MTLTextureDescriptor* texDesc =
	    [MTLTextureDescriptorClass texture2DDescriptorWithPixelFormat: MTLPixelFormatRGBA8Unorm width: w height: h mipmapped: NO];

	id<MTLTexture> tex = [UnityGetMetalDevice() newTextureWithDescriptor: texDesc];

	MTLRegion r = MTLRegionMake3D(0, 0, 0, w, h, 1);
	[tex replaceRegion: r mipmapLevel: 0 withBytes: data bytesPerRow: w * 4];

The returned texture id is later used in TestNativeTexture.cs to create Unity Texture2D from it:

	testTex = Texture2D.CreateExternalTexture(128, 128, TextureFormat.ARGB32, false, false, curTex);
	target.material.mainTexture = testTex;

When you press "Show Next" button it will cycle through loaded textures and reuse Texture object to point to different gles texture.
Please note, that both textures have exact same setup: same extensions, format etc.
If you want to change texture setup, you should create new Unity Texture (in case of creating from native texture, the texture is supposed to be non readable, so no extra memory is allocated)
