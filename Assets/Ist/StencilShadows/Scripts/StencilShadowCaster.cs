using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    [AddComponentMenu("Ist/Stencil Shadows/Caster")]
    [RequireComponent(typeof(Renderer))]
    [ExecuteInEditMode]
    public class StencilShadowCaster : IStencilShadowCaster
    {
        public Material[] m_stencil_materials;


#if UNITY_EDITOR
        void Reset()
        {
            var renderer = GetComponent<Renderer>();
            var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/StencilShadows/Materials/Stencil.mat");
            m_stencil_materials = new Material[renderer.sharedMaterials.Length];
            for (int i = 0; i < m_stencil_materials.Length; ++i )
            {
                m_stencil_materials[i] = mat;
            }
        }
#endif // UNITY_EDITOR


        void EnableKeywords(LightWithStencilShadow light)
        {
            switch(light.m_type)
            {
                case LightWithStencilShadow.Type.Point:
                    m_stencil_materials[0].EnableKeyword ("PROJECTION_POINT");
                    m_stencil_materials[0].DisableKeyword("PROJECTION_LINE");
                    break;
                case LightWithStencilShadow.Type.Line:
                    m_stencil_materials[0].DisableKeyword("PROJECTION_POINT");
                    m_stencil_materials[0].EnableKeyword ("PROJECTION_LINE");
                    break;
            }

            if (light.m_inverse)
            {
                m_stencil_materials[0].EnableKeyword("ENABLE_INVERSE");
            }
            else
            {
                m_stencil_materials[0].DisableKeyword("ENABLE_INVERSE");
            }
        }

        public override void IssueDrawCall_FrontStencil(LightWithStencilShadow light, CommandBuffer commands)
        {
            EnableKeywords(light);
            var renderer = GetComponent<Renderer>();
            int n = m_stencil_materials.Length;
            for (int i = 0; i < n; ++i)
            {
                commands.DrawRenderer(renderer, m_stencil_materials[i], i, 0);
            }
        }

        public override void IssueDrawCall_BackStencil(LightWithStencilShadow light, CommandBuffer commands)
        {
            var renderer = GetComponent<Renderer>();
            int n = m_stencil_materials.Length;
            for (int i = 0; i < n; ++i)
            {
                commands.DrawRenderer(renderer, m_stencil_materials[i], i, 1);
            }
        }
    }

}