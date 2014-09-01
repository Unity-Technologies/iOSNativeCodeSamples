using UnityEngine;
using System.Runtime.InteropServices;


public class QueryVersion : MonoBehaviour
{
#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern string QueryUnityVersion();
#else
    private static string QueryUnityVersion()          { return null; }
#endif

    private string version = null;
    public TextMesh versionText;

    void Update()
    {
        if (version == null)
        {
            version = QueryUnityVersion();
            if (version != null)
                Debug.Log("Just Fetched: " + version);
        }
    }

    void OnGUI()
    {
        if (version != null)
            versionText.text = version;
    }
}
