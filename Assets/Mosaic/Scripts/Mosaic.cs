using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(Camera))]
[RequireComponent(typeof(FrameBufferUtils))]
public class Mosaic : MonoBehaviour
{
#if UNITY_EDITOR
    void Reset()
    {
        GetComponent<FrameBufferUtils>().m_enable_frame_buffer = true;
    }
#endif // UNITY_EDITOR
}
