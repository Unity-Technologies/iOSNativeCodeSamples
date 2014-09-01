using UnityEngine;
using System.Collections;

public class TestWWWGetCustomConnection : MonoBehaviour
{
    IEnumerator LoadStuff()
    {
        // sure, for testing reaction to custom "Secret" header you might need to have special scripts on your server, so we skip it
        WWW www = new WWW("http://unity3d.com/profiles/unity3d/themes/unity/images/company/brand/logos/pwrdby/pwrdby.jpg");
        yield return www;

        renderer.material.mainTexture = www.texture;
    }

    void Start()
    {
        StartCoroutine(LoadStuff());
    }
}
