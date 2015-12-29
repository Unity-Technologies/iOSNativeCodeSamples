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
    [DllImport("__Internal")]
    private static extern void SetCaptureBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer);
    [DllImport("__Internal")]
    private static extern void SetRenderBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer);
    [DllImport ("__Internal")]
    private static extern System.IntPtr GetRenderEventFunc();
#else
    private static void SetCaptureBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer) {}
    private static void SetRenderBuffers(System.IntPtr colorBuffer, System.IntPtr depthBuffer)  {}
    private static System.IntPtr GetRenderEventFunc()                                           { return System.IntPtr.Zero; }
#endif

    void Start()
    {
        RenderTexture rt = GetComponent<Camera>().targetTexture;
        // make sure rt is created, as OnPreRender will be called before setting it as active RT, and lazy creation would not kick in yet
        if (rt)
            rt.Create();
    }

    void OnPreRender()
    {
        RenderTexture rt = GetComponent<Camera>().targetTexture;

        RenderBuffer colorBuffer = rt ? rt.colorBuffer : Display.main.colorBuffer;
        RenderBuffer depthBuffer = rt ? rt.depthBuffer : Display.main.depthBuffer;
        if (pluginBehaviour == PluginBehaviour.Capture)
            SetCaptureBuffers(colorBuffer.GetNativeRenderBufferPtr(), depthBuffer.GetNativeRenderBufferPtr());
        else
            SetRenderBuffers(colorBuffer.GetNativeRenderBufferPtr(), depthBuffer.GetNativeRenderBufferPtr());
    }

    void OnPostRender()
    {
        GL.IssuePluginEvent(GetRenderEventFunc(), pluginBehaviour == PluginBehaviour.Capture ? 0 : 1);
    }
}
