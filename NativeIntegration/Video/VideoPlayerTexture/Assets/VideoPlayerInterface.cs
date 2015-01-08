using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class
VideoPlayerInterface
{
#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern bool VideoPlayer_CanOutputToTexture(string filename);
    [DllImport("__Internal")]
    private static extern bool VideoPlayer_PlayerReady();
    [DllImport("__Internal")]
    private static extern float VideoPlayer_DurationSeconds();
    [DllImport("__Internal")]
    private static extern void VideoPlayer_VideoExtents(ref int w, ref int h);
    [DllImport("__Internal")]
    private static extern System.IntPtr VideoPlayer_CurFrameTexture();
    [DllImport("__Internal")]
    private static extern bool VideoPlayer_PlayVideo(string filename);
#else // if UNITY_IPHONE && !UNITY_EDITOR
    private static bool VideoPlayer_CanOutputToTexture(string filename) { return false; }
    private static bool VideoPlayer_PlayerReady()                       { return false; }
    private static float VideoPlayer_DurationSeconds()                  { return 0.0f; }
    private static void VideoPlayer_VideoExtents(ref int w, ref int h)  { }
    private static System.IntPtr VideoPlayer_CurFrameTexture()          { return System.IntPtr.Zero; }
    private static bool VideoPlayer_PlayVideo(string filename)          { return false; }
#endif // if UNITY_IPHONE && !UNITY_EDITOR

    private Texture2D _videoTexture = null;


    public static bool CanOutputToTexture(string filename)
    {
        return VideoPlayer_CanOutputToTexture(filename);
    }

    public void play(string filename)
    {
        if (CanOutputToTexture(filename))
            VideoPlayer_PlayVideo(filename);
    }

    public bool videoReady { get { return VideoPlayer_PlayerReady(); } }
    public float videoDuration { get { return VideoPlayer_DurationSeconds(); } }

    public int videoWidth
    {
        get
        {
            int w = 0, h = 0;
            VideoPlayer_VideoExtents(ref w, ref h);
            return w;
        }
    }
    public int videoHeight
    {
        get
        {
            int w = 0, h = 0;
            VideoPlayer_VideoExtents(ref w, ref h);
            return h;
        }
    }


    public Texture2D videoTexture
    {
        get
        {
            System.IntPtr nativeTex = videoReady ? VideoPlayer_CurFrameTexture() : System.IntPtr.Zero;
            if (nativeTex != System.IntPtr.Zero)
            {
                if (_videoTexture == null)
                {
                    _videoTexture = Texture2D.CreateExternalTexture(videoWidth, videoHeight, TextureFormat.BGRA32, false, false, nativeTex);
                    _videoTexture.filterMode = FilterMode.Bilinear;
                    _videoTexture.wrapMode = TextureWrapMode.Repeat;
                }

                _videoTexture.UpdateExternalTexture(nativeTex);
            }
            else
            {
                _videoTexture = null;
            }

            return _videoTexture;
        }
    }
};
