using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class TestMetalPlugin : MonoBehaviour
{
	public enum
	PluginBehaviour
	{
		Capture,
		Render
	};
	public PluginBehaviour pluginBehaviour = PluginBehaviour.Render;


#if UNITY_IPHONE && !UNITY_EDITOR
	[DllImport ("__Internal")]
	private static extern void SetTargetRT(System.IntPtr texture);
#else
	private static void SetTargetRT(System.IntPtr texture)	{}
#endif


	void Start()
	{
		if(pluginBehaviour == PluginBehaviour.Capture)
		{
			RenderTexture rt = GetComponent<Camera>().targetTexture;

			// make sure we explicitly create RT and not wait for auto-create when camera starts render to it
			rt.Create();
			SetTargetRT(rt.GetNativeTexturePtr());
		}
	}

	void OnPostRender()
	{
		GL.IssuePluginEvent(pluginBehaviour == PluginBehaviour.Capture ? 0 : 1);
	}
}
