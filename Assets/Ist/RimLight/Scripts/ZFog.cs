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
    [AddComponentMenu("Ist/Z Fog")]
    public class ZFog : MonoBehaviour
    {
        public Color m_color1 = new Color(0.75f, 0.75f, 1.0f, 1.0f);
        public float m_hdr1 = 1.0f;
        public float m_near1 = 10.0f;
        public float m_far1 = 30.0f;
        public float m_pow1 = 1.0f;

        public Color m_color2 = new Color(0.75f, 0.75f, 1.0f, 1.0f);
        public float m_hdr2 = 1.0f;
        public float m_near2 = 10.0f;
        public float m_far2 = 30.0f;
        public float m_pow2 = 1.0f;


        public Shader m_shader;
        Material m_material;

        public Vector4 GetLinearColor1()
        {
            return new Vector4(
                Mathf.GammaToLinearSpace(m_color1.r*m_hdr1),
                Mathf.GammaToLinearSpace(m_color1.g*m_hdr1),
                Mathf.GammaToLinearSpace(m_color1.b*m_hdr1),
                m_color1.a
            );
        }

        public Vector4 GetLinearColor2()
        {
            return new Vector4(
                Mathf.GammaToLinearSpace(m_color2.r * m_hdr2),
                Mathf.GammaToLinearSpace(m_color2.g * m_hdr2),
                Mathf.GammaToLinearSpace(m_color2.b * m_hdr2),
                m_color2.a
            );
        }

#if UNITY_EDITOR
        void Reset()
        {
            m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/RimLight/Shaders/ZFog.shader");
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

            m_material.SetVector("_Color1", GetLinearColor1());
            m_material.SetVector("_Params1", new Vector4(m_near1, m_far1, m_pow1, 0.0f));
            m_material.SetVector("_Color2", GetLinearColor2());
            m_material.SetVector("_Params2", new Vector4(m_near2, m_far2, m_pow2, 0.0f));
            Graphics.Blit(src, dst, m_material);
        }
    }
}