using UnityEngine;
using System.Collections;

public class Rotator : MonoBehaviour
{
    public Transform target = null;

    void Update()
    {
        target.Rotate(Vector3.up * (8.0f * Time.deltaTime));
        target.Rotate(Vector3.right * (-4.0f * Time.deltaTime));
    }
}
