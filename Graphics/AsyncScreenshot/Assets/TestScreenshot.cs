using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;
using AOT;

public class TestScreenshot : MonoBehaviour
{
    private static bool savingScreenshot = false;


    private delegate void ScreenshotCompleteDelegate();
    [MonoPInvokeCallback(typeof(ScreenshotCompleteDelegate))]
    public static void ScreenshotCompleteCallback()
    {
        // it might be called outside of player loop, so we shouldnt do anything funky
        savingScreenshot = false;
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
            Application.CaptureScreenshot("test.png");
#endif
        }
    }
}
