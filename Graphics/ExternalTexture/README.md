# Creating Unity Texture from GLES Texture


## Description

This is a sample of usage of **Texture2D.CreateExternalTexture** and **Texture2D.UpdateExternalTexture**. It will load png into gles texture in native plugin and give it back to Unity to be used like normal Unity Texture.


##Prerequisites

Unity: 4.2

iOS: any


## How does it work

There are two pieces of interest: TestGLESTexture.cs and Plugins/iOS/GlesTexture.mm.

In Plugins/iOS folder you can see three files: GlesTexture.mm (native plugin) and two images that we will use: Test_UnityLogoLarge.png and Test_Icon.png. All of them will be copied to your project, so we can load png from App Bundle.

GlesTexture.mm contains just one function:

	extern "C" void* GLESTexture_CreateTexture(const char* image_filename, int* w, int* h)

It will load png image from App Bundle to UIImage and pass this data to OpenGL ES:

	glBindTexture(GL_TEXTURE_2D, texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageW, imageH, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);

The returned texture id is later used in TestGLESTexture.cs to create Unity Texture2D from it:

	testTex = Texture2D.CreateExternalTexture(externalTexture[0].w, externalTexture[0].h, TextureFormat.ARGB32, false, false, externalTexture[0].tex);
	tex.filterMode = FilterMode.Bilinear;
	tex.wrapMode = TextureWrapMode.Repeat;

Please note, that we made sure that texture settings (wrap mode and filtering) do match.

When you press "Show Next" button it will cycle through loaded textures and reuse Texture object to point to different gles texture.
Please note, that both textures have exact same setup: same extensions, format etc.
If you want to change texture setup, you should create new Unity Texture (in case of creating from native texture, the texture is supposed to be non readable, so no extra memory is allocated)
