using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/SubtractedSkinnedMesh")]
[RequireComponent(typeof(SkinnedMeshRenderer))]
[ExecuteInEditMode]
public class SubReceiverSkinnedMesh : ISubReceiver
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
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtracted.mat");
        var materials = new Material[renderer.sharedMaterials.Length];
        for (int i = 0; i < renderer.sharedMaterials.Length; ++i)
        {
            materials[i] = mat;
        }
        renderer.sharedMaterials = materials;

        var mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Depth.mat");
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

    public override void IssueDrawCall_BackDepth(SubRenderer br, CommandBuffer cb)
    {
        Mesh mesh = GetMesh();
        Matrix4x4 trs = GetTRS();
        int n = mesh.subMeshCount;
        for (int i = 0; i < n; ++i)
        {
            cb.DrawMesh(mesh, trs, m_depth_materials[i], i, 0);
        }
    }

    public override void IssueDrawCall_FrontDepth(SubRenderer br, CommandBuffer cb)
    {
        Mesh mesh = GetMesh();
        Matrix4x4 trs = GetTRS();
        int n = mesh.subMeshCount;
        for (int i = 0; i < n; ++i)
        {
            cb.DrawMesh(mesh, trs, m_depth_materials[i], i, 1);
        }
    }

    public override void IssueDrawCall_GBuffer(SubRenderer br, CommandBuffer cb)
    {

    }
}
