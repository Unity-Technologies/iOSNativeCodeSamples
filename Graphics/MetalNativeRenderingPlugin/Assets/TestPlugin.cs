using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestPlugin : MonoBehaviour {
	IEnumerator OnFrameEnd() {
		yield return new WaitForEndOfFrame();
		// note that we do that AFTER all unity rendering is done.
		// it is especially important if AA is involved, as we will end encoder (resulting in AA resolve)
		SamplePlugin.DoCopyRT(GetComponent<Camera>().targetTexture, null);
		yield return null;
	}

	void OnPostRender() {
		SamplePlugin.DoExtraDrawCall();
		StartCoroutine(OnFrameEnd());
	}
}
