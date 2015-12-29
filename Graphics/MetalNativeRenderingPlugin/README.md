# Using Unity Low-level Native Plugin Interface with Metal


## Description

This is a sample of usage of native Low-level Native Plugin Interface. It will show both using custom render encoder and hooking up to unity's one


##Prerequisites

Unity: 5.4

iOS: 8.0 (Metal support)


## How does it work

First of all we have 2 cameras: one that will render to RenderTexture and another that renders to screen.
We will use the first one's OnPostRender to copy RenderTexture contents to native-side texture, and the second one's OnPostRender to render on native side (simple rect with captured texture).

Inside OnPreRender we will simply pass target RenderBuffer's to native side. Please note that we enforce RenderTexture creation in Start (otherwise, as RenderTexture's are created lazily we might end up with null buffers in first OnPreRender).
Another point of note is that we check if we render to RT or not and use Display buffers as target if we render to screen. The tricky part is that we want to pass "native" render buffers, so we can query appropriate into later on. 

Here is the code:

	RenderBuffer colorBuffer = rt ? rt.colorBuffer : Display.main.colorBuffer;
	RenderBuffer depthBuffer = rt ? rt.depthBuffer : Display.main.depthBuffer;
	if(pluginBehaviour == PluginBehaviour.Capture)
		SetCaptureBuffers(colorBuffer.GetNativeRenderBufferPtr(), depthBuffer.GetNativeRenderBufferPtr());
	else
		SetRenderBuffers(colorBuffer.GetNativeRenderBufferPtr(), depthBuffer.GetNativeRenderBufferPtr());


Inside OnPostRender we issue plugin event (different ones for capture/render).


So as you see all the interesting stuff is happening inside our plugin.

First of all we do:

	- (void)shouldAttachRenderDelegate;
	{
		UnityRegisterRenderingPluginV5(&UnityPluginLoad, &UnityPluginUnload);
	}


That is simply registering our UnityPluginLoad and UnityPluginUnload, as on iOS we cannot use dynamic libraries (hence we cannot load functions from them by name as we usually do on other platforms).

Inside UnityPluginLoad we store interface pointers:

	s_UnityInterfaces   = unityInterfaces;
	s_Graphics          = s_UnityInterfaces->Get<IUnityGraphics>();
	s_MetalGraphics     = s_UnityInterfaces->Get<IUnityGraphicsMetal>();

Later on we will be using s_MetalGraphics, as it contains pointers to functions unity provides to plugin.

SetCaptureBuffers and SetRenderBuffers are showing the usage of new api: querying MTLTexture from native unity Render Buffer (the one coming from RenderBuffer.GetNativeRenderBufferPtr()):


	extern "C" void SetCaptureBuffers(void* colorBuffer, void* depthBuffer)
	{
		g_CaptureTexture = s_MetalGraphics->TextureFromRenderBuffer((UnityRenderBuffer)colorBuffer);
	}
	extern "C" void SetRenderBuffers(void* colorBuffer, void* depthBuffer)
	{
		g_RenderColorTexture    = s_MetalGraphics->TextureFromRenderBuffer((UnityRenderBuffer)colorBuffer);
		g_RenderDepthTexture    = s_MetalGraphics->TextureFromRenderBuffer((UnityRenderBuffer)depthBuffer);
		g_RenderStencilTexture  = s_MetalGraphics->StencilTextureFromRenderBuffer((UnityRenderBuffer)depthBuffer);
	}


As we won't go there into using Metal api, there are only two places of interest left.
First of all on doing "capture" we need to end current unity's encoder (to be able to do our own), so we call

	s_MetalGraphics->EndCurrentCommandEncoder();

That will make sure that current unity's rendering (up to this point) is ended cleanly. Please not that if you do your custom MTLCommandEncoder you absolutely *must* end it before returning control to unity

On doing "render" we simply want to use current unity's encoder to render alongside unity so we do


	id<MTLRenderCommandEncoder> cmd = (id<MTLRenderCommandEncoder>)s_MetalGraphics->CurrentCommandEncoder();

