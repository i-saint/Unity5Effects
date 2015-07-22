using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif


[RequireComponent(typeof(Camera))]
public class WaterCaustics : MonoBehaviour
{
    public float m_speed = 1.00f;
    public float m_intensity = 1.00f;
    public Shader m_shader;
    Material m_material;
    CommandBuffer m_cb;
    CameraEvent m_timing = CameraEvent.AfterSkybox;


#if UNITY_EDITOR
    void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath("Assets/IstEffects/WaterSurface/Shaders/WaterCaustics.shader", typeof(Shader)) as Shader;
    }
#endif // UNITY_EDITOR

    void OnEnable()
    {
    }

    void OnDisable()
    {
        ReleaseCommandBuffer();
    }

    void Awake()
    {
        m_material = new Material(m_shader);
    }


    void ReleaseCommandBuffer()
    {
        if (m_cb != null)
        {
            GetComponent<Camera>().RemoveCommandBuffer(m_timing, m_cb);
            m_cb.Release();
            m_cb = null;
        }
    }

    void OnPreRender()
    {
        if (m_cb == null)
        {
            m_cb = new CommandBuffer();
            m_cb.name = "Caustics";
            GetComponent<Camera>().AddCommandBuffer(m_timing, m_cb);
        }

        m_cb.Clear();
        WaterCausticsField.instances.ForEach((e) =>
        {
            m_cb.DrawMesh(e.GetMesh(), e.GetMatrix(), m_material);
        });

        m_material.SetFloat("g_speed", m_speed);
        m_material.SetFloat("g_intensity", m_intensity);
    }
}
