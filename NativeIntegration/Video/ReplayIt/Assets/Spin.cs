using UnityEngine;
using System.Collections;

public class Spin : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
		GetComponent<Transform>().Rotate(Time.deltaTime * 60, Time.deltaTime * 60, Time.deltaTime * 60);
	}
}
