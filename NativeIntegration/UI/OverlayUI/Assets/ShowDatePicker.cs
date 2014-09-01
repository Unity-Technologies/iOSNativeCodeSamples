using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;
using AOT;

public class ShowDatePicker : MonoBehaviour
{
    public GUIText curDateText;
    public int buttonExt = 100;

    private delegate void StringParamDelegate(string str);

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void ShowNativeDatePicker(StringParamDelegate dateSelected);
    [DllImport("__Internal")]
    private static extern void HideNativeDatePicker();
#else
    private static void ShowNativeDatePicker(StringParamDelegate dateSelected)  { }
    private static void HideNativeDatePicker()                                  { }
#endif

    private static bool _DatePickerShown = false;
    private static string _CurDate         = "no date";

    [MonoPInvokeCallback(typeof(StringParamDelegate))]
    public static void DateSelectedCallback(string str)
    {
        _CurDate = str;
    }

    void OnGUI()
    {
        if (GUI.Button(new Rect(10, 10, buttonExt, buttonExt), "Pick Date"))
        {
            ShowNativeDatePicker(DateSelectedCallback);
            _DatePickerShown = true;
        }

        curDateText.text = _CurDate;

        if (_DatePickerShown)
        {
            if (GUI.Button(new Rect(Screen.width - buttonExt, Screen.height - buttonExt, buttonExt, buttonExt), "Stop Date"))
            {
                HideNativeDatePicker();
                _DatePickerShown = false;
            }
        }
    }
}
