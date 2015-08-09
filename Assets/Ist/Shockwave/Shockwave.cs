using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class Shockwave : MonoBehaviour
{
    [Range(-0.5f, 0.5f)] public float m_radius = 0.5f;
    public float m_attenuation_pow = 0.5f;
    public Vector3 m_offset_center = Vector3.zero;

    public float m_reverse = 0.0f;
    public float m_highlighting = 1.0f;
    public bool m_debug = false;
    public Shader m_shader;

    Material m_material;

#if UNITY_EDITOR
    void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/Shockwave/Shockwave.shader");
        GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Utilities/Meshes/IcoSphereI2.asset");
    }
#endif // UNITY_EDITOR

    void Update()
    {
        if (m_material == null)
        {
            m_material = new Material(m_shader);
            GetComponent<MeshRenderer>().sharedMaterial = m_material;
        }

        if(m_debug) { m_material.EnableKeyword ("ENABLE_DEBUG"); }
        else        { m_material.DisableKeyword("ENABLE_DEBUG"); }

        m_material.SetVector("_Params1", new Vector4(m_radius, m_attenuation_pow, m_reverse, m_highlighting));
        m_material.SetVector("_Scale", GetComponent<Transform>().localScale);
        m_material.SetVector("_OffsetCenter", m_offset_center);
    }
}
