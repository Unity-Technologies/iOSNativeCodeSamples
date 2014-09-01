# Loading raw texture data directly


## Description

This is a sample of usage of **Texture2D.LoadRawTextureData**. It will load downloaded pvr data into texture.


##Prerequisites

Unity: 4.3

iOS: any


## How does it work

This sample is purely C# so everything is in LoadPVRTexture.cs. To simplify sample we use PVR texture directly, which is not very efficient because we will need to skip file header at runtime, but we chose that way so you can see PVR texture contents in the editor.

We start by "downloading" data (for sake of simplicity we put image in StreamingAssets) and get rid of the header

	string filePath = System.IO.Path.Combine(Application.streamingAssetsPath, "Test_UnityLogoLarge.pvr");
	...
	texMem = System.IO.File.ReadAllBytes(filePath).Skip(_HeaderSize).ToArray();

And then we load raw data into texture. Please be aware that we do almost no checks in there, so you can, for example, load DXT texture data here, though it will obviously result in OpenGL ES errors.

	targetTex.LoadRawTextureData(texMem);
	targetTex.Apply(true, true);
