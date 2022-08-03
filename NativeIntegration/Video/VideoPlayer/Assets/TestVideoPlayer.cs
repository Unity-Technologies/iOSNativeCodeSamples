using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class TestVideoPlayer : MonoBehaviour
{
#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void VideoPlayer_PlayVideo(string url);
    [DllImport("__Internal")]
    private static extern void VideoPlayer_PauseVideo();
    [DllImport("__Internal")]
    private static extern void VideoPlayer_ResumeVideo();
    [DllImport("__Internal")]
    private static extern void VideoPlayer_RewindVideo();
#else // if UNITY_IPHONE && !UNITY_EDITOR
    private static void VideoPlayer_PlayVideo(string url)   {}
    private static void VideoPlayer_PauseVideo()            {}
    private static void VideoPlayer_ResumeVideo()           {}
    private static void VideoPlayer_RewindVideo()           {}
#endif // if UNITY_IPHONE && !UNITY_EDITOR

    private string[] videoPath = new string[]
    {
        "Data/Raw/big_buck_bunny.mp4",
    };
    private int curVideo = 0;

    private void PlayVideo()
    {
        VideoPlayer_PlayVideo(videoPath[curVideo]);
        curVideo = (curVideo + 1) % videoPath.Length;
    }

    void Start()
    {
        PlayVideo();
    }

    void OnGUI()
    {
        int buttonW = Screen.width / 8;
        int buttonH = Screen.height / 8;
        int buttonX = 10;
        int buttonY = Screen.height - buttonH - 10;

        if (GUI.Button(new Rect(buttonX, buttonY, buttonW, buttonH), "Next"))
            PlayVideo();

        buttonX += buttonW + 10;
        if (GUI.Button(new Rect(buttonX, buttonY, buttonW, buttonH), "Pause"))
            VideoPlayer_PauseVideo();

        buttonX += buttonW + 10;
        if (GUI.Button(new Rect(buttonX, buttonY, buttonW, buttonH), "Resume"))
            VideoPlayer_ResumeVideo();

        buttonX += buttonW + 10;
        if (GUI.Button(new Rect(buttonX, buttonY, buttonW, buttonH), "Rewind"))
            VideoPlayer_RewindVideo();
    }
}
