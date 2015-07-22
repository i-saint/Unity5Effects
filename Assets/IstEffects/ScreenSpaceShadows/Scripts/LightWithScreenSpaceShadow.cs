using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    [AddComponentMenu("IstEffects/ScreenSpaceShadow/Light")]
    [ExecuteInEditMode]
    public class LightWithScreenSpaceShadow : MonoBehaviour
    {
        public enum Type
        {
            Point,
            Line,
        }
        public enum Sample
        {
            Fast,
            Medium,
            High,
        }
        public Type m_type;
        public bool m_cast_shadow = true;
        public Sample m_sample;
        public float m_range = 10.0f;
        public Color m_color = Color.white;
        public float m_intensity = 1.0f;
        public float m_inner_radius = 0.0f;
        public float m_capsule_length = 1.0f;
        public float m_occulusion_strength = 3.0f;


        #region static
        static private List<LightWithScreenSpaceShadow> s_instances;
        static public List<LightWithScreenSpaceShadow> instances
        {
            get
            {
                if (s_instances == null) { s_instances = new List<LightWithScreenSpaceShadow>(); }
                return s_instances;
            }
        }
        #endregion

        public Vector4 GetPositionAndRadius()
        {
            var pos = GetComponent<Transform>().position;
            return new Vector4(pos.x, pos.y, pos.z, m_range);
        }
        public Vector4 GetLinearColor()
        {
            return new Vector4(
                Mathf.GammaToLinearSpace(m_color.r * m_intensity),
                Mathf.GammaToLinearSpace(m_color.g * m_intensity),
                Mathf.GammaToLinearSpace(m_color.b * m_intensity),
                1.0f
            );
        }
        public Vector4 GetParams()
        {
            return new Vector4(m_inner_radius, m_capsule_length, (float)m_type, m_occulusion_strength);
        }
        public Matrix4x4 GetTRS()
        {
            return GetComponent<Transform>().localToWorldMatrix;
        }


#if UNITY_EDITOR
#endif // UNITY_EDITOR


        void OnEnable()
        {
            instances.Add(this);
        }

        void OnDisable()
        {
            instances.Remove(this);
        }


        void OnDrawGizmos()
        {
            Gizmos.DrawIcon(transform.position, m_type == Type.Line ? "AreaLight Gizmo" : "PointLight Gizmo", true);
        }

        void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(0.1f, 0.7f, 1.0f, 0.6f);
            if (m_type == Type.Line)
            {
                Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, new Vector3(m_capsule_length * 2, m_inner_radius * 2, m_inner_radius * 2));
                Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
            }
            else
            {
                Gizmos.matrix = Matrix4x4.identity;
                Gizmos.DrawWireSphere(transform.position, m_inner_radius);
            }
            Gizmos.matrix = Matrix4x4.identity;
            Gizmos.DrawWireSphere(transform.position, m_range);
        }
    }
}