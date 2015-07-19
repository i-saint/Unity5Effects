using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/AndOperatorSkinnedMesh")]
[RequireComponent(typeof(SkinnedMeshRenderer))]
[ExecuteInEditMode]
public class AndOperatorSkinnedMesh : IAndOperator
{
    public Material[] m_materials;
    public Material[] m_depth_materials;
    Mesh m_mesh;

    Mesh GetMesh()
    {
        if (m_mesh == null) { m_mesh = new Mesh(); }
        return m_mesh;
    }
    Matrix4x4 GetTRS() { return GetComponent<Transform>().localToWorldMatrix; }

#if UNITY_EDITOR
    public override void Reset()
    {
        base.Reset();
        var renderer = GetComponent<SkinnedMeshRenderer>();
        renderer.sharedMaterials = new Material[0];

        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/ScreenSpaceBoolean/Materials/Default_And.mat");
        m_materials = new Material[renderer.sharedMesh.subMeshCount];
        for (int i = 0; i < m_materials.Length; ++i)
        {
            m_materials[i] = mat;
        }

        var mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/ScreenSpaceBoolean/Materials/Depth.mat");
        m_depth_materials = new Material[m_materials.Length];
        for (int i = 0; i < m_depth_materials.Length; ++i)
        {
            m_depth_materials[i] = mat_depth;
        }
    }
#endif // UNITY_EDITOR

    void LateUpdate()
    {
        var mesh = GetMesh();
        Matrix4x4 trs = GetTRS();
        GetComponent<SkinnedMeshRenderer>().BakeMesh(mesh);
        for (int i = 0; i < mesh.subMeshCount; ++i)
        {
            Graphics.DrawMesh(mesh, trs, m_materials[i], 0, null, i);
        }
    }

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
