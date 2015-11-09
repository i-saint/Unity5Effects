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
    public class CausticsField : MonoBehaviour
    {
        public enum AttenuationModel
        {
            None,
            Directional,
            Radial,
        }
        public Color m_color = new Color(0.8f, 0.8f, 1.0f, 1.0f);
        public float m_scroll_speed = 1.00f;
        public float m_scale = 2.0f;
        public float m_intensity = 0.3f;
        public float m_wave_pow = 10.0f;
        public AttenuationModel m_attenuation_model = AttenuationModel.Directional;
        public float m_attenuation = 0.1f;
        public float m_attenuation_pow = 1.5f;
        public Shader m_shader;
        Material m_material;


#if UNITY_EDITOR
        void Reset()
        {
            m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/WaterSurface/Shaders/CausticsField.shader");
        }
#endif

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
                renderer.sharedMaterial = m_material;
                renderer.shadowCastingMode = ShadowCastingMode.Off;
                renderer.receiveShadows = false;
            }

            m_material.SetVector("_Color", m_color);
            m_material.SetVector("_Params1", new Vector4(m_scroll_speed, m_scale, m_intensity, m_wave_pow));
            m_material.SetVector("_Params2", new Vector4(m_attenuation, m_attenuation_pow, 0.0f, 0.0f));

            switch (m_attenuation_model)
            {
                case AttenuationModel.None:
                    m_material.EnableKeyword("ATTENUATION_NONE");
                    m_material.DisableKeyword("ATTENUATION_DIRECTIONAL");
                    m_material.DisableKeyword("ATTENUATION_RADIAL");
                    break;
                case AttenuationModel.Directional:
                    m_material.DisableKeyword("ATTENUATION_NONE");
                    m_material.EnableKeyword("ATTENUATION_DIRECTIONAL");
                    m_material.DisableKeyword("ATTENUATION_RADIAL");
                    break;
                case AttenuationModel.Radial:
                    m_material.DisableKeyword("ATTENUATION_NONE");
                    m_material.DisableKeyword("ATTENUATION_DIRECTIONAL");
                    m_material.EnableKeyword("ATTENUATION_RADIAL");
                    break;
            }
        }
    }
}
