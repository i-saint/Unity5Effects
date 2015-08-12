using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    [AddComponentMenu("Ist/Screen Space Boolean/And Operator")]
    [RequireComponent(typeof(Renderer))]
    [ExecuteInEditMode]
    public class AndOperator : IAndOperator
    {
        public Material[] m_depth_materials;

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

            var mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/ScreenSpaceBoolean/Materials/Depth.mat");
            m_depth_materials = new Material[materials.Length];
            for (int i = 0; i < m_depth_materials.Length; ++i)
            {
                m_depth_materials[i] = mat_depth;
            }
        }
#endif // UNITY_EDITOR

        public override void IssueDrawCall_BackDepth(AndRenderer br, CommandBuffer cb)
        {
            var renderer = GetComponent<Renderer>();
            int n = m_depth_materials.Length;
            for (int i = 0; i < n; ++i)
            {
                cb.DrawRenderer(renderer, m_depth_materials[i], i, 0);
            }
        }

        public override void IssueDrawCall_FrontDepth(AndRenderer br, CommandBuffer cb)
        {
            var renderer = GetComponent<Renderer>();
            int n = m_depth_materials.Length;
            for (int i = 0; i < n; ++i)
            {
                cb.DrawRenderer(renderer, m_depth_materials[i], i, 1);
            }
        }
    }

}