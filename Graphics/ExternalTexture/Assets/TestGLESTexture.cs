using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class TestGLESTexture : MonoBehaviour
{
    public Material testMaterial = null;
    private Texture2D testTex = null;

#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern System.IntPtr GLESTexture_CreateTexture(string filename, ref int w, ref int h);
#else
    private static System.IntPtr GLESTexture_CreateTexture(string filename, ref int w, ref int h)
    {
        Texture2D tex = (Texture2D)Resources.LoadAssetAtPath("Assets/Plugins/iOS/" + filename + ".png", typeof(Texture2D));
        return tex.GetNativeTexturePtr();
    }
#endif


    private struct
    ExternalTextureDesc
    {
        public System.IntPtr tex;
        public int w;
        public int h;
    };

    private ExternalTextureDesc[] externalTexture = new ExternalTextureDesc[2];
    int curTex = 0;

    void Start()
    {
        externalTexture[0].tex = GLESTexture_CreateTexture("Test_UnityLogoLarge", ref externalTexture[0].w, ref externalTexture[0].h);
        externalTexture[1].tex = GLESTexture_CreateTexture("Test_Icon", ref externalTexture[1].w, ref externalTexture[1].h);

        testTex = Texture2D.CreateExternalTexture(externalTexture[0].w, externalTexture[0].h, TextureFormat.ARGB32, false, false, externalTexture[0].tex);
        testTex.filterMode = FilterMode.Bilinear;
        testTex.wrapMode = TextureWrapMode.Repeat;

        testMaterial.mainTexture = testTex;
    }

    void OnGUI()
    {
        if (GUI.Button(new Rect(10, 10, 200, 200), "Show Next"))
        {
            curTex = (curTex + 1) % 2;
            testTex.UpdateExternalTexture(externalTexture[curTex].tex);
        }
    }
}
