using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;
using System;

public class GalleryTextureLoader : MonoBehaviour
{
    public GameObject cube;

    [DllImport("__Internal")]
    private extern static void RequestImages();

    [DllImport("__Internal")]
    private extern static int GetGalleryImageCount();

    [DllImport("__Internal")]
    private extern static bool GetGalleryLoadingFinished();

    [DllImport("__Internal")]
    private extern static IntPtr GetGalleryImage(int idx, out int sz);

    [DllImport("__Internal")]
    private extern static IntPtr GetImageBuffer(IntPtr handle);

    [DllImport("__Internal")]
    private extern static void ReleaseImage(IntPtr handle);


    // Use this for initialization
    IEnumerator Start()
    {
        #if !UNITY_EDITOR
        RequestImages();

        // Images are scanned asynchronously
        while (!GetGalleryLoadingFinished())
            yield return null;

        if (GetGalleryImageCount() > 0)
        {
            int sz = 0;
            IntPtr handle = GetGalleryImage(0, out sz);
            IntPtr data = GetImageBuffer(handle);

            byte[] image = new byte[sz];
            Marshal.Copy(data, image, 0, sz);

            var tex = new Texture2D(4, 4);
            tex.LoadImage(image);
            cube.renderer.material.mainTexture = tex;

            ReleaseImage(handle);
        }
        #endif // if !UNITY_EDITOR

        yield break;
    }

    // Update is called once per frame
    void Update()
    {
    }
}
