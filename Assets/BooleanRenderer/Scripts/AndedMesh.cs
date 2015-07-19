using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/AndedMesh")]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class AndedMesh : IAnded
{
    public Material[] m_depth_materials;

#if UNITY_EDITOR
    public override void Reset()
    {
        base.Reset();
        var renderer = GetComponent<MeshRenderer>();
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtracted.mat");
        var materials = new Material[renderer.sharedMaterials.Length];
        for (int i = 0; i < materials.Length; ++i)
        {
            materials[i] = mat;
        }
        renderer.sharedMaterials = materials;

        var mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Depth.mat");
        m_depth_materials = new Material[materials.Length];
        for (int i = 0; i < m_depth_materials.Length; ++i)
        {
            m_depth_materials[i] = mat_depth;
        }
    }
#endif // UNITY_EDITOR

    Mesh GetMesh() { return GetComponent<MeshFilter>().sharedMesh; }
    Matrix4x4 GetTRS() { return GetComponent<Transform>().localToWorldMatrix; }

    public override void IssueDrawCall_BackDepth(AndRenderer br, CommandBuffer cb)
    {
        var m = GetMesh();
        var n = m_depth_materials.Length;
        var t = GetTRS();
        for (int i = 0; i < n; ++i)
        {
            cb.DrawMesh(m, t, m_depth_materials[i], i, 0);
        }
    }

    public override void IssueDrawCall_FrontDepth(AndRenderer br, CommandBuffer cb)
    {
        var m = GetMesh();
        int n = m_depth_materials.Length;
        var t = GetTRS();
        for (int i = 0; i < n; ++i)
        {
            cb.DrawMesh(m, t, m_depth_materials[i], i, 1);
        }
    }
}
