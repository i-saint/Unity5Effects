using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Ist
{
    [RequireComponent(typeof(Renderer))]
    [ExecuteInEditMode]
    public class WaterSurface : MonoBehaviour
    {
        public enum Sample
        {
            Fast,
            Medium,
            High,
        }
        public Sample m_sample = Sample.Medium;
        public float m_scroll_speed = 1.00f;
        public float m_scale = 2.0f;
        public float m_refraction = 0.025f;
        public float m_reflection = 0.1f;

        public float m_fresnel_bias = 0.0f;
        public float m_fresnel_scale = 0.03f;
        public float m_fresnel_pow = 5.0f;
        public Color m_fresnel_color = Color.white;

        public float m_march_step = 0.2f;
        public float m_march_boost = 1.4f;
        public float m_attenuation = 0.1f;
        public Color m_falloff_color = Color.black;

        public int m_render_queue = 0;

        public Shader m_shader;
        Material m_material;


#if UNITY_EDITOR
        void Reset()
        {
            m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/WaterSurface/Shaders/WaterSurface.shader");
        }
#endif // UNITY_EDITOR

        void OnDestroy()
        {
            if (m_material != null)
            {
                DestroyImmediate(m_material);
            }
        }

        void OnWillRenderObject()
        {
            if (m_material == null)
            {
                var renderer = GetComponent<Renderer>();
                m_material = new Material(m_shader);
                if(m_render_queue==0) { m_render_queue = m_material.renderQueue; }
                m_material.renderQueue = m_render_queue;
                renderer.sharedMaterial = m_material;
                renderer.shadowCastingMode = ShadowCastingMode.Off;
                renderer.receiveShadows = false;
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

            m_material.SetVector("_Params1", new Vector4(m_scroll_speed, m_scale, m_march_step, m_march_boost));
            m_material.SetVector("_Params2", new Vector4(m_refraction, m_reflection, m_attenuation, 0.0f));
            m_material.SetVector("_Params3", new Vector4(m_fresnel_bias, m_fresnel_scale, m_fresnel_pow, 0.0f));
            m_material.SetVector("_FresnelColor", m_fresnel_color);
            m_material.SetVector("_FalloffColor", m_falloff_color);
        }
    }
}