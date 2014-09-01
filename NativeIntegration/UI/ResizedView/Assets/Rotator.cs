using UnityEngine;
using System.Collections;

public class Rotator : MonoBehaviour
{
    void Update()
    {
        transform.Rotate(Vector3.right * 10 * Time.deltaTime);
        transform.Rotate(Vector3.up * 10 * Time.deltaTime, Space.World);
    }
}
