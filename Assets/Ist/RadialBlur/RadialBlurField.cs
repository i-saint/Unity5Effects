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
public class RadialBlurField : MonoBehaviour
{
    public enum Sample
    {
        Fast,
        Medium,
        High,
    }

    public Sample m_sample = Sample.Medium;
    public float m_radius = 0.5f;
    public float m_attenuation_pow = 0.5f;
    public Vector3 m_offset_center = Vector3.zero;
    public Vector3 m_color_bias = Vector3.one;
    public Vector3 m_bloom_threshold = new Vector3(0.5f, 0.5f, 0.5f);
    public Vector3 m_bloom_intensity = Vector3.one;

    public float m_reverse = 0.0f;
    public bool m_blur = true;
    public bool m_bloom = true;
    public bool m_attenuation = true;
    public bool m_debug = false;
    public Shader m_shader;

    Material m_material;

#if UNITY_EDITOR
    void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/RadialBlur/RadialBlur.shader");
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

        switch (m_sample)
        {
            case Sample.Fast:
                m_material.EnableKeyword ("QUALITY_FAST");
                m_material.DisableKeyword("QUALITY_MEDIUM");
                m_material.DisableKeyword("QUALITY_HIGH");
                break;
            case Sample.Medium:
                m_material.DisableKeyword("QUALITY_FAST");
                m_material.EnableKeyword ("QUALITY_MEDIUM");
                m_material.DisableKeyword("QUALITY_HIGH");
                break;
            case Sample.High:
                m_material.DisableKeyword("QUALITY_FAST");
                m_material.DisableKeyword("QUALITY_MEDIUM");
                m_material.EnableKeyword ("QUALITY_HIGH");
                break;
        }

        if (m_blur) { m_material.EnableKeyword ("ENABLE_BLUR"); }
        else        { m_material.DisableKeyword("ENABLE_BLUR"); }

        if(m_bloom) { m_material.EnableKeyword ("ENABLE_BLOOM"); }
        else        { m_material.DisableKeyword("ENABLE_BLOOM"); }

        if(m_attenuation)   { m_material.EnableKeyword ("ENABLE_ATTENUATION"); }
        else                { m_material.DisableKeyword("ENABLE_ATTENUATION"); }
        
        if(m_debug) { m_material.EnableKeyword ("ENABLE_DEBUG"); }
        else        { m_material.DisableKeyword("ENABLE_DEBUG"); }

        m_material.SetVector("_Params1", new Vector4(m_radius, m_attenuation_pow, m_reverse, 0));
        m_material.SetVector("_Scale", GetComponent<Transform>().localScale);
        m_material.SetVector("_OffsetCenter", m_offset_center);
        m_material.SetVector("_ColorBias", m_color_bias);
        m_material.SetVector("_BloomThreshold", m_bloom_threshold);
        m_material.SetVector("_BloomIntensity", m_bloom_intensity);
    }
}
