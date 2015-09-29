using UnityEngine;
using System.Collections;

public class SwitchScene : MonoBehaviour {
	public int levelToLoad;
	
	void OnGUI()
	{
		if (GUI.Button(new Rect(Screen.width - 260, Screen.height - 110, 250, 100), "Switch scene"))
			Application.LoadLevel(levelToLoad);
	}
}
