using UnityEngine;
using System.Collections;
using System.Linq;

public class LoadPVRTexture : MonoBehaviour
{
    public Material targetMat = null;
    private Texture2D targetTex = null;


#if UNITY_IPHONE && !UNITY_EDITOR
    private const int _HeaderSize = 52;
#else
    private const int _HeaderSize = 0;
#endif


    void Start()
    {
    #if UNITY_IPHONE && !UNITY_EDITOR
        targetTex = new Texture2D(128, 128, TextureFormat.PVRTC_RGBA4, true);
    #else
        targetTex = new Texture2D(128, 128);
    #endif

        StartCoroutine(LoadTexture());
        targetMat.mainTexture = targetTex;
    }

    IEnumerator LoadTexture()
    {
    #if UNITY_IPHONE && !UNITY_EDITOR
        string filePath = System.IO.Path.Combine(Application.streamingAssetsPath, "Test_UnityLogoLarge.pvr");
    #else
        string filePath = System.IO.Path.Combine(Application.streamingAssetsPath, "Test_UnityLogoLarge.png");
    #endif

        byte[] texMem = null;
        if (filePath.Contains("://"))
        {
            WWW www = new WWW(filePath);
            yield return www;
            texMem = www.bytes.Skip(_HeaderSize).ToArray();
        }
        else
        {
            texMem = System.IO.File.ReadAllBytes(filePath).Skip(_HeaderSize).ToArray();
        }

    #if UNITY_IPHONE && !UNITY_EDITOR
        targetTex.LoadRawTextureData(texMem);
        targetTex.Apply(true, true);
    #else
        targetTex.LoadImage(texMem);
    #endif

        yield break;
    }
}
