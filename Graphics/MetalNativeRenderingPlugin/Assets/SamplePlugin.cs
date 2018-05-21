using System.Runtime.InteropServices;
using UnityEngine;

public class SamplePlugin {

    // we will do several pretty useless events to show the usage of all api functions
    private enum EventType {
        ExtraDrawCall = 0,  // will do an extra draw call to currently setup rt with custom shader
        CopyRTtoRT,         // copy src rt to internal texture and draws rect using it to dst rt
    };

    public static void DoExtraDrawCall() {
        GL.IssuePluginEvent(GetRenderEventFunc(), (int)EventType.ExtraDrawCall);
    }
    public static void DoCopyRT(RenderTexture srcRT, RenderTexture dstRT) {
        RenderBuffer src = srcRT ? srcRT.colorBuffer : Display.main.colorBuffer, dst = dstRT ? dstRT.colorBuffer : Display.main.colorBuffer;
        SetRTCopyTargets(src.GetNativeRenderBufferPtr(), dst.GetNativeRenderBufferPtr());
        GL.IssuePluginEvent(GetRenderEventFunc(), (int)EventType.CopyRTtoRT);
    }


    // native plugin interop:
    // GetRenderEventFunc is used to query plugin for function pointer to pass to GL.IssuePluginEvent

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport ("__Internal")] private static extern System.IntPtr GetRenderEventFunc();
    [DllImport ("__Internal")] private static extern void SetRTCopyTargets(System.IntPtr srcRB, System.IntPtr dstRB);
#else
    private static System.IntPtr GetRenderEventFunc() { return System.IntPtr.Zero; }
    private static void SetRTCopyTargets(System.IntPtr srcRB, System.IntPtr dstRB) {}
#endif

}
