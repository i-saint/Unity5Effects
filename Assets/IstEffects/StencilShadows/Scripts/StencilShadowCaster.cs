using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    [AddComponentMenu("IstEffects/StencilShadow/Caster")]
    [RequireComponent(typeof(Renderer))]
    public class StencilShadowCaster : IStencilShadowCaster
    {
        public Material[] m_stencil_materials;


#if UNITY_EDITOR
        void Reset()
        {
            var renderer = GetComponent<Renderer>();
            var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/IstEffects/StencilShadows/Materials/Stencil.mat");
            m_stencil_materials = new Material[renderer.sharedMaterials.Length];
            for (int i = 0; i < m_stencil_materials.Length; ++i )
            {
                m_stencil_materials[i] = mat;
            }
        }
#endif // UNITY_EDITOR


        public override void IssueDrawCall_FrontStencil(LightWithStencilShadow light, CommandBuffer commands)
        {
            m_stencil_materials[0].EnableKeyword("PROJECTION_POINT");
            m_stencil_materials[0].EnableKeyword("ENABLE_INVERSE");
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