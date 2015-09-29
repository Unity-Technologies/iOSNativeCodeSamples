using System;
using System.Runtime.InteropServices;

namespace UnityEngine.iOS
{

delegate int internalCall();

public class ReplayKit {
	private static void doInternalCall(internalCall call)
	{
		int ret = call();
		if (ret == 0)
		{
			string err = UnityReplayKitLastError();
			if (err == null)
				err = "Unkown error occurred";
			throw new Exception(err);	
		}
	}
	
	public static bool recordingAvailable
	{
		get {
#if UNITY_IOS && !UNITY_EDITOR
			return UnityReplayKitRecordingAvailable() > 0;
#else
			return false;
#endif
		}
	}
	
	[DllImport("__Internal")]
	private static extern int UnityReplayKitRecordingAvailable();
	
	public static string lastError
	{
		get {
#if UNITY_IOS && !UNITY_EDITOR
			return UnityReplayKitLastError();
#else
			return "";
#endif
		}
	}
	
	[DllImport("__Internal")]
	private static extern string UnityReplayKitLastError();

	public static void StartRecording(bool enableMicrophone = false)
	{
#if UNITY_IOS && !UNITY_EDITOR
		doInternalCall(() => { return UnityReplayKitStartRecording(enableMicrophone ? 1 : 0); });
#endif
	}
	
	[DllImport("__Internal")]
	private static extern int UnityReplayKitStartRecording(int enableMicrophone);
	
	public static void StopRecording()
	{
#if UNITY_IOS && !UNITY_EDITOR
		doInternalCall(UnityReplayKitStopRecording);
#endif
	}
	
	public static bool isRecording
	{
		get {
			bool recording = false;
#if UNITY_IOS && !UNITY_EDITOR
			recording = UnityReplayKitIsRecording() > 0;
#endif
			return recording;
		}
	}
	
	[DllImport("__Internal")]
	private static extern int UnityReplayKitIsRecording();
	
	[DllImport("__Internal")]
	private static extern int UnityReplayKitStopRecording();
	
	public static void Preview()
	{
#if UNITY_IOS && !UNITY_EDITOR
		doInternalCall(UnityReplayKitPreview);
#endif
	}
	
	[DllImport("__Internal")]
	private static extern int UnityReplayKitPreview();
	
	public static void Discard()
	{
#if UNITY_IOS && !UNITY_EDITOR
		doInternalCall(UnityReplayKitDiscard);
#endif
	}
	
	[DllImport("__Internal")]
	private static extern int UnityReplayKitDiscard();
}

}
