using UnityEngine;
using System.Collections;

public class TestVideo : MonoBehaviour
{
    public Material videoMat = null;
    private bool videoMatTexAssigned = false;

    private VideoPlayerInterface _player = new VideoPlayerInterface();


    void Start()
    {
        videoMat.mainTexture = null;
        _player.play("Data/Raw/big_buck_bunny.mp4");
    }

    void Update()
    {
        if (!videoMatTexAssigned && _player.videoTexture)
        {
            videoMat.mainTexture = _player.videoTexture;
            videoMatTexAssigned = true;
        }
        if (videoMatTexAssigned && !_player.videoTexture)
        {
            videoMat.mainTexture = null;
            videoMatTexAssigned = false;
        }
    }
}
