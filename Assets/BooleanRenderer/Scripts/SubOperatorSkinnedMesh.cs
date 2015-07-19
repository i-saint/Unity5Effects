using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/SubOperatorSkinnedMesh")]
[RequireComponent(typeof(SkinnedMeshRenderer))]
[ExecuteInEditMode]
public class SubOperatorSkinnedMesh : ISubOperator
{
    public Material[] m_materials;
    public Material[] m_mask_materials;
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

        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_SubOperator.mat");
        m_materials = new Material[renderer.sharedMesh.subMeshCount];
        for (int i = 0; i < m_materials.Length; ++i)
        {
            m_materials[i] = mat;
        }

        var mat_mask = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/StencilMask.mat");
        m_mask_materials = new Material[m_materials.Length];
        for (int i = 0; i < m_mask_materials.Length; ++i)
        {
            m_mask_materials[i] = mat_mask;
        }
    }
#endif // UNITY_EDITOR

    void LateUpdate()
    {
        var mesh = GetMesh();
        Matrix4x4 trs = GetTRS();
        GetComponent<SkinnedMeshRenderer>().BakeMesh(mesh);
        for (int i = 0; i < mesh.subMeshCount; ++i )
        {
            Graphics.DrawMesh(mesh, trs, m_materials[i], 0, null, i);
        }
    }

    public override void IssueDrawCall_DepthMask(SubRenderer br, CommandBuffer cb)
    {
        if (br.m_enable_piercing)
        {
            for (int i = 0; i < m_mask_materials.Length; ++i)
            {
                m_mask_materials[i].EnableKeyword("ENABLE_PIERCING");
            }
        }
        else
        {
            for (int i = 0; i < m_mask_materials.Length; ++i)
            {
                m_mask_materials[i].DisableKeyword("ENABLE_PIERCING");
            }
        }

        Matrix4x4 trs = GetTRS();
        Mesh mesh = GetMesh();
        int n = mesh.subMeshCount;
        if (br.m_enable_masking)
        {
            for (int i = 0; i < n; ++i)
            {
                cb.DrawMesh(mesh, trs, m_mask_materials[i], i, 0);
                cb.DrawMesh(mesh, trs, m_mask_materials[i], i, 1);
                cb.DrawMesh(mesh, trs, m_mask_materials[i], i, 2);
            }
        }
        else
        {
            for (int i = 0; i < n; ++i)
            {
                cb.DrawMesh(mesh, trs, m_mask_materials[i], i, 3);
            }
        }
    }

    public override void IssueDrawCall_GBuffer(SubRenderer br, CommandBuffer cb)
    {

    }
}
