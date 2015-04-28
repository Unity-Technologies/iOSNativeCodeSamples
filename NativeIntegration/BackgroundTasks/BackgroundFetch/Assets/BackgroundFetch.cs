using UnityEngine;
using System.Runtime.InteropServices;


public class BackgroundFetch : MonoBehaviour
{
#if UNITY_IPHONE && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern string QueryFetchedText();
#else
    private static string QueryFetchedText()          { return null; }
#endif

    private string fetchedText = null;
    public TextMesh text;

    void Update()
    {
        if (fetchedText == null)
        {
            fetchedText = QueryFetchedText();
            if (fetchedText != null)
                Debug.Log("Just Fetched: " + fetchedText);
        }
    }

    void OnGUI()
    {
        if (fetchedText != null)
            text.text = fetchedText;
    }
}
