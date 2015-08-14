using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
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

        public float m_radius = 0.5f;
        public Sample m_sample = Sample.Medium;
        public float m_blur_distance = 0.5f;
        public float m_attenuation_pow = 0.5f;
        public Vector3 m_offset_center = Vector3.zero;
        public Vector3 m_color_bias = Vector3.one;
        public Vector3 m_bloom_threshold = new Vector3(0.5f, 0.5f, 0.5f);
        public Vector3 m_bloom_intensity = Vector3.one;

        public float m_reverse = 0.0f;
        public bool m_debug = false;

        public float m_lifetime = 1.0f;
        public float m_animation;

        protected Material m_material;
        protected Animator m_animator;


        public virtual void Die() { Destroy(gameObject); }


#if UNITY_EDITOR
        public virtual void Reset()
        {
            GetComponent<Renderer>().sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/RadialBlur/RadialBlurField.mat");
            GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Utilities/Meshes/IcoSphereI2.asset");
        }
#endif // UNITY_EDITOR

        public virtual void Start()
        {
            m_animator = GetComponent<Animator>();
            if (m_animator != null)
            {
                m_animator.speed = 1.0f / m_lifetime;
            }
        }

        public virtual void Update()
        {
            var trans = GetComponent<Transform>();
            var s = m_radius * 2.0f;
            trans.localScale = new Vector3(s, s, s);

            if(m_animator!=null && m_animator.GetCurrentAnimatorStateInfo(0).normalizedTime > 1.0f)
            {
                Die();
            }
        }

        public virtual void OnWillRenderObject()
        {
            if (m_material == null)
            {
                m_material = new Material(GetComponent<Renderer>().sharedMaterial);
                GetComponent<Renderer>().sharedMaterial = m_material;
            }

            switch (m_sample)
            {
                case Sample.Fast:
                    m_material.EnableKeyword("QUALITY_FAST");
                    m_material.DisableKeyword("QUALITY_MEDIUM");
                    m_material.DisableKeyword("QUALITY_HIGH");
                    break;
                case Sample.Medium:
                    m_material.DisableKeyword("QUALITY_FAST");
                    m_material.EnableKeyword("QUALITY_MEDIUM");
                    m_material.DisableKeyword("QUALITY_HIGH");
                    break;
                case Sample.High:
                    m_material.DisableKeyword("QUALITY_FAST");
                    m_material.DisableKeyword("QUALITY_MEDIUM");
                    m_material.EnableKeyword("QUALITY_HIGH");
                    break;
            }

            if (m_debug) { m_material.EnableKeyword("ENABLE_DEBUG"); }
            else { m_material.DisableKeyword("ENABLE_DEBUG"); }

            m_material.SetVector("_Params1", new Vector4(m_blur_distance * m_animation, m_attenuation_pow, m_reverse, 0));
            m_material.SetVector("_Scale", GetComponent<Transform>().localScale);
            m_material.SetVector("_OffsetCenter", m_offset_center);
            m_material.SetVector("_ColorBias", m_color_bias);
            m_material.SetVector("_BloomThreshold", m_bloom_threshold);
            m_material.SetVector("_BloomIntensity", m_bloom_intensity);
        }
    }
}
