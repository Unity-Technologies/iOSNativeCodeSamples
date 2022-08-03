using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;
using AOT;

public class TestOrientation : MonoBehaviour
{
#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern int   UnityInterfaceOrientation();
    [DllImport("__Internal")]
    private static extern void  UnityChangeInterfaceOrientation(int orient);
#endif

    IEnumerator ChangeOrientation()
    {
        yield return new WaitForEndOfFrame();
#if UNITY_IPHONE && !UNITY_EDITOR
        ScreenOrientation   orientation = (ScreenOrientation)UnityInterfaceOrientation();
        bool                isPortrait  = orientation == ScreenOrientation.Portrait || orientation == ScreenOrientation.PortraitUpsideDown;

        UnityChangeInterfaceOrientation((int)(isPortrait ? ScreenOrientation.LandscapeLeft : ScreenOrientation.Portrait));
#endif
    }

    void OnGUI()
    {
#if UNITY_IPHONE && !UNITY_EDITOR
        ScreenOrientation   orientation = (ScreenOrientation)UnityInterfaceOrientation();
        bool                isPortrait  = orientation == ScreenOrientation.Portrait || orientation == ScreenOrientation.PortraitUpsideDown;

        if (GUI.Button(new Rect(Screen.width - 210, 10, 200, 200), isPortrait ? "Landscape" : "Portrait"))
            StartCoroutine(ChangeOrientation());
#endif
    }
}
