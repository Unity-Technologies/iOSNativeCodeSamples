using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestMetalShader : MonoBehaviour
{
	public Shader shader;

	private Texture2D CreateTexture(int ext)
	{
		Texture2D tex = new Texture2D(ext,ext,TextureFormat.RGBA32, false,false);

		Color[] pixels = new Color[ext*ext];
		for(int i = 0 ; i < ext ; ++i)
		{
			for(int j = 0 ; j < ext ; ++j)
			{
				// we do 4x4 blocks
				if((i/4) % 2 == (j/4) % 2) pixels[i*ext+j] = new Color(1,1,1,1);
				else pixels[i*ext+j] = new Color(0,0,0,1);
			}
		}
		tex.SetPixels(pixels);
		tex.Apply(false, false);

		return tex;
	}

	void Start()
	{
		Material mat = new Material(shader);
		mat.mainTexture = CreateTexture(64);
		mat.color = new Color(1,0,0,1);
		GetComponent<Renderer>().material = mat;
	}
}
