using System;
using UnityEngine;
using UnityEngine.iOS;

public class Replay : MonoBehaviour {
	string lastError = "";
	void OnGUI()
	{
		var recording = ReplayKit.isRecording;
		string caption = recording ? "Stop Recording" : "Start Recording";
		if (GUI.Button(new Rect(10, 10, 500, 200), caption))
		{
			try {
				recording = !recording;
				if (recording)
					ReplayKit.StartRecording();
				else
				{
					ReplayKit.StopRecording();
				}
			}
			catch (Exception e) {
				lastError = e.ToString();
			}
		}
		
		GUI.Label(new Rect(10, 220, 500, 50), "Last error: " + ReplayKit.lastError);
		GUI.Label(new Rect(10, 280, 500, 50), "Last exception: " + lastError);
		
		if (ReplayKit.recordingAvailable)
		{
			if (GUI.Button(new Rect(10, 350, 500, 200), "Preview"))
			{
				ReplayKit.Preview();
			}
			if (GUI.Button(new Rect(10, 560, 500, 200), "Discard"))
			    {
				ReplayKit.Discard();
			}
		}
	}
}
