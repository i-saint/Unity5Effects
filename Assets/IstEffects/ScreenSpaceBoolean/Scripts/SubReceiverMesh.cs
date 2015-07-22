using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("IstEffects/ScreenSpaceBoolean/SubReceiverMesh")]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class SubReceiverMesh : ISubReceiver
{
    public Material[] m_materials;
    public Material[] m_depth_materials;

#if UNITY_EDITOR
    public override void Reset()
    {
        base.Reset();
        var renderer = GetComponent<MeshRenderer>();
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

    Mesh GetMesh() { return GetComponent<MeshFilter>().sharedMesh; }
    Matrix4x4 GetTRS() { return GetComponent<Transform>().localToWorldMatrix; }

    public override void IssueDrawCall_BackDepth(SubRenderer br, CommandBuffer cb)
    {
        var m = GetMesh();
        var n = m_depth_materials.Length;
        var t = GetTRS();
        for (int i = 0; i < n; ++i )
        {
            cb.DrawMesh(m, t, m_depth_materials[i], i, 0);
        }
    }

    public override void IssueDrawCall_FrontDepth(SubRenderer br, CommandBuffer cb)
    {
        var m = GetMesh();
        int n = m_depth_materials.Length;
        var t = GetTRS();
        for (int i = 0; i < n; ++i)
        {
            cb.DrawMesh(m, t, m_depth_materials[i], i, 1);
        }
    }

    public override void IssueDrawCall_GBuffer(SubRenderer br, CommandBuffer cb)
    {

    }
}
