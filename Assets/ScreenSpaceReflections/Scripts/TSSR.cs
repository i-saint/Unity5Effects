using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

public class TSSR : MonoBehaviour
{
    public float m_block_size = 15.0f;
    public Shader m_mosaic_shader;
    Material m_mat_mosaic;
    Dictionary<Camera, CommandBuffer> m_cameras = new Dictionary<Camera, CommandBuffer>();


#if UNITY_EDITOR
    void Reset()
    {
    }
#endif // UNITY_EDITOR

    void OnDisable()
    {
    }

    void Update()
    {
    }

    void OnWillRenderObject()
    {
    }
}
