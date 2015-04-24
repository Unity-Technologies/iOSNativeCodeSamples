using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class TestMetalPlugin : MonoBehaviour
{
	public enum
	PluginBehaviour
	{
		Capture,
		Render
	};
	public PluginBehaviour pluginBehaviour = PluginBehaviour.Render;


#if UNITY_IPHONE && !UNITY_EDITOR
	[DllImport ("__Internal")]
	private static extern void SetCaptureBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer);
	[DllImport ("__Internal")]
	private static extern void SetRenderBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer);
#else
	private static void SetCaptureBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer)	{}
	private static void SetRenderBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer)	{}
#endif

	void OnPreRender()
	{
		RenderTexture rt = GetComponent<Camera>().targetTexture;
		if(rt)
			rt.Create();

		RenderBuffer colorBuffer = rt ? rt.colorBuffer : Display.main.colorBuffer;
		RenderBuffer depthBuffer = rt ? rt.depthBuffer : Display.main.depthBuffer;
		if(pluginBehaviour == PluginBehaviour.Capture)
			SetCaptureBuffers(colorBuffer.GetNativeRenderBufferPtr(), depthBuffer.GetNativeRenderBufferPtr());
		else
			SetRenderBuffers(colorBuffer.GetNativeRenderBufferPtr(), depthBuffer.GetNativeRenderBufferPtr());
	}

	void OnPostRender()
	{
		GL.IssuePluginEvent(pluginBehaviour == PluginBehaviour.Capture ? 0 : 1);
	}
}
