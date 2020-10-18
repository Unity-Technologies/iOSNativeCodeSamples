using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;
using AOT;

public class Screenshot : MonoBehaviour
{
    private static int screenshotIndex = 1;
    private static string curScreenshotName;

    private static string GenerateScreenshotName()
    {
        return "test" + screenshotIndex++ + ".png";
    }

    private static bool savingScreenshot = false;

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void OnScreenshotDone(string filename);
#endif


    private delegate void ScreenshotCompleteDelegate();
    [MonoPInvokeCallback(typeof(ScreenshotCompleteDelegate))]
    public static void ScreenshotCompleteCallback()
    {
        // it might be called outside of player loop, so we shouldnt do anything funky
        savingScreenshot = false;
    #if UNITY_IPHONE && !UNITY_EDITOR
        OnScreenshotDone("test.png");
    #endif
    }

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void CaptureScreenshot(ScreenshotCompleteDelegate completed, string filename);
#endif

    void OnGUI()
    {
        if (!savingScreenshot && GUI.Button(new Rect(10, 10, 200, 200), "Screenshot"))
        {
#if UNITY_IPHONE && !UNITY_EDITOR
            savingScreenshot = true;
            CaptureScreenshot(ScreenshotCompleteCallback, "test.png");
#else
            ScreenCapture.CaptureScreenshot("test.png");
#endif
        }
    }
}
