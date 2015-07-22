using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("IstEffects/ScreenSpaceBoolean/SubReceiver")]
[RequireComponent(typeof(Renderer))]
[ExecuteInEditMode]
public class SubReceiver : ISubReceiver
{
    public Material[] m_depth_materials;

#if UNITY_EDITOR
    public override void Reset()
    {
        base.Reset();
        var renderer = GetComponent<Renderer>();
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/IstEffects/ScreenSpaceBoolean/Materials/Default_SubReceiver.mat");
        var materials = new Material[renderer.sharedMaterials.Length];
        for (int i = 0; i < materials.Length; ++i)
        {
            materials[i] = mat;
        }
        renderer.sharedMaterials = materials;

        var mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/IstEffects/ScreenSpaceBoolean/Materials/Depth.mat");
        m_depth_materials = new Material[materials.Length];
        for (int i = 0; i < m_depth_materials.Length; ++i)
        {
            m_depth_materials[i] = mat_depth;
        }
    }
#endif // UNITY_EDITOR

    public override void IssueDrawCall_BackDepth(SubRenderer br, CommandBuffer cb)
    {
        var renderer = GetComponent<Renderer>();
        int n = m_depth_materials.Length;
        for (int i = 0; i < n; ++i)
        {
            cb.DrawRenderer(renderer, m_depth_materials[i], i, 0);
        }
    }

    public override void IssueDrawCall_FrontDepth(SubRenderer br, CommandBuffer cb)
    {
        var renderer = GetComponent<Renderer>();
        int n = m_depth_materials.Length;
        for (int i = 0; i < n; ++i)
        {
            cb.DrawRenderer(renderer, m_depth_materials[i], i, 1);
        }
    }
}
