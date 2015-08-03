using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    [RequireComponent(typeof(Camera))]
    [RequireComponent(typeof(GBufferUtils))]
    [ExecuteInEditMode]
    [AddComponentMenu("Ist/RimLight")]
    public class RimLight : MonoBehaviour
    {
        public Color m_color = new Color(0.75f, 0.75f, 1.0f, 0.0f);
        public float m_intensity = 1.0f;
        public float m_fresnel_bias = 0.0f;
        public float m_fresnel_scale = 5.0f;
        public float m_fresnel_pow = 5.0f;

        public bool m_edge_highlighting = true;
        public float m_edge_intensity = 0.3f;
        [Range(0.0f, .99f)]
        public float m_edge_threshold = 0.8f;
        public float m_edge_radius = 1.0f;
        public bool m_mul_smoothness = true;
        public Shader m_shader;
        Material m_material;

        public Vector4 GetLinearColor()
        {
            return new Vector4(
                Mathf.GammaToLinearSpace(m_color.r),
                Mathf.GammaToLinearSpace(m_color.g),
                Mathf.GammaToLinearSpace(m_color.b),
                1.0f
            );
        }

#if UNITY_EDITOR
        void Reset()
        {
            m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/RimLight/Shaders/RimLight.shader");
            GetComponent<GBufferUtils>().m_enable_inv_matrices = true;
        }
#endif // UNITY_EDITOR

        void OnDestroy()
        {
            if (m_material != null)
            {
                Object.DestroyImmediate(m_material);
            }
        }

        [ImageEffectOpaque]
        void OnRenderImage(RenderTexture src, RenderTexture dst)
        {
            if (m_material == null)
            {
                m_material = new Material(m_shader);
            }

            if (m_edge_highlighting)
            {
                m_material.EnableKeyword("ENABLE_EDGE_HIGHLIGHTING");
            }
            else
            {
                m_material.DisableKeyword("ENABLE_EDGE_HIGHLIGHTING");
            }

            if (m_mul_smoothness)
            {
                m_material.EnableKeyword("ENABLE_SMOOTHNESS_ATTENUAION");
            }
            else
            {
                m_material.DisableKeyword("ENABLE_SMOOTHNESS_ATTENUAION");
            }

            m_material.SetVector("_Color", GetLinearColor());
            m_material.SetVector("_Params1", new Vector4(m_fresnel_bias, m_fresnel_scale, m_fresnel_pow, m_intensity));
            m_material.SetVector("_Params2", new Vector4(m_edge_intensity, m_edge_threshold, m_edge_radius, 0.0f));
            Graphics.Blit(src, dst, m_material);
        }
    }
}