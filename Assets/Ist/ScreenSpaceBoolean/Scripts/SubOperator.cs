using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


namespace Ist
{
    [AddComponentMenu("Ist/Screen Space Boolean/Sub Operator")]
    [RequireComponent(typeof(Renderer))]
    [ExecuteInEditMode]
    public class SubOperator : ISubOperator
    {
        public Material[] m_mask_materials;

#if UNITY_EDITOR
        void Reset()
        {
            var renderer = GetComponent<Renderer>();
            var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/ScreenSpaceBoolean/Materials/Default_Boolean.mat");
            var materials = new Material[renderer.sharedMaterials.Length];
            for (int i = 0; i < materials.Length; ++i)
            {
                materials[i] = mat;
            }
            renderer.sharedMaterials = materials;
            renderer.shadowCastingMode = ShadowCastingMode.Off;

            var mat_mask = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/ScreenSpaceBoolean/Materials/StencilMask.mat");
            m_mask_materials = new Material[materials.Length];
            for (int i = 0; i < m_mask_materials.Length; ++i)
            {
                m_mask_materials[i] = mat_mask;
            }
        }
#endif // UNITY_EDITOR

        public override void IssueDrawCall_DepthMask(SubRenderer br, CommandBuffer cb)
        {
            var renderer = GetComponent<Renderer>();
            int n = m_mask_materials.Length;
            for (int i = 0; i < n; ++i)
            {
                cb.DrawRenderer(renderer, m_mask_materials[i], i, 0);
                cb.DrawRenderer(renderer, m_mask_materials[i], i, 1);
                if (br.m_enable_piercing)
                {
                    cb.DrawRenderer(renderer, m_mask_materials[i], i, 2);
                }
                cb.DrawRenderer(renderer, m_mask_materials[i], i, 3);
            }
        }
    }
}