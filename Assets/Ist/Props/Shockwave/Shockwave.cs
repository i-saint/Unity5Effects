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
    public class Shockwave : MonoBehaviour
    {
        public float m_lifetime = 1.0f;
        public float m_radius_start = 0.5f;
        public float m_radius_end = 0.5f;

        [Range(-0.5f, 0.5f)]
        public float m_distortion_distance = 0.5f;
        public float m_attenuation_pow = 0.5f;
        public Vector3 m_offset_center = Vector3.zero;

        public float m_reverse = 0.0f;

        public float m_animation_radius;
        public float m_animation_distortion;

        public bool m_debug = false;

        Material m_material;
        protected Animator m_animator;


        public virtual void Die() { Destroy(gameObject); }


#if UNITY_EDITOR
        public virtual void Reset()
        {
            GetComponent<Renderer>().sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/Shockwave/Shockwave.mat");
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
            var s = Mathf.Lerp(m_radius_start * 2.0f, m_radius_end * 2.0f, m_animation_radius);
            trans.localScale = new Vector3(s, s, s);

            if (m_animator != null && m_animator.GetCurrentAnimatorStateInfo(0).normalizedTime > 1.0f)
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

            if (m_debug) { m_material.EnableKeyword("ENABLE_DEBUG"); }
            else { m_material.DisableKeyword("ENABLE_DEBUG"); }

            m_material.SetVector("_Params1", new Vector4(m_distortion_distance * m_animation_distortion, m_attenuation_pow, m_reverse, 0.0f));
            m_material.SetVector("_Scale", GetComponent<Transform>().localScale);
            m_material.SetVector("_OffsetCenter", m_offset_center);
        }
    }
}
