using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class TestNativeTexture : MonoBehaviour
{
    private Texture2D   testTex = null;
    public  Renderer    target  = null;


#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern System.IntPtr CreateNativeTexture(string filename);
    [DllImport("__Internal")]
    private static extern void DestroyNativeTexture(System.IntPtr tex);
#else
    private static System.IntPtr CreateNativeTexture(string filename)
    {
        Texture2D tex = (Texture2D)UnityEditor.AssetDatabase.LoadAssetAtPath("Assets/Plugins/iOS/" + filename + ".png", typeof(Texture2D));
        return tex.GetNativeTexturePtr();
    }

    private static void DestroyNativeTexture(System.IntPtr tex)
    {
    }

#endif // if UNITY_IPHONE && !UNITY_EDITOR

    private string[]    externalTexture = new string[] { "Test_UnityLogoLarge", "Test_Icon", "Soft" };
    private int         curTexIndex;

    private System.IntPtr   curTex;

    void LoadTexture()
    {
        System.IntPtr texToDestroy = curTex;

        curTexIndex = (curTexIndex + 1) % externalTexture.Length;
        curTex      = CreateNativeTexture(externalTexture[curTexIndex]);

        if(testTex == null)
        {
            testTex = Texture2D.CreateExternalTexture(128, 128, TextureFormat.ARGB32, false, false, curTex);
            target.material.mainTexture = testTex;
        }
        else
        {
            testTex.UpdateExternalTexture(curTex);
        }

        if (texToDestroy != System.IntPtr.Zero)
            DestroyNativeTexture(texToDestroy);
    }

    void Start()
    {
        curTexIndex = -1;
        curTex = System.IntPtr.Zero;
        LoadTexture();
    }

    void OnGUI()
    {
        if (GUI.Button(new Rect(10, 10, 200, 200), "Show Next"))
            LoadTexture();
    }
}
