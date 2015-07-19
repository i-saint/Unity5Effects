using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/SubtractorMesh")]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class SubOperatorMesh : ISubOperator
{
    public Material[] m_materials;
    public Material[] m_mask_materials;

#if UNITY_EDITOR
    public override void Reset()
    {
        base.Reset();
        var renderer = GetComponent<MeshRenderer>();
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtractor.mat");
        var materials = new Material[renderer.sharedMaterials.Length];
        for (int i = 0; i < materials.Length; ++i)
        {
            materials[i] = mat;
        }
        renderer.sharedMaterials = materials;

        var mat_mask = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/StencilMask.mat");
        m_mask_materials = new Material[materials.Length];
        for (int i = 0; i < m_mask_materials.Length; ++i)
        {
            m_mask_materials[i] = mat_mask;
        }
    }
#endif // UNITY_EDITOR

    Mesh GetMesh() { return GetComponent<MeshFilter>().sharedMesh; }
    Matrix4x4 GetTRS() { return GetComponent<Transform>().localToWorldMatrix; }

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

        Mesh m = GetMesh();
        int n = m.subMeshCount;
        Matrix4x4 t = GetTRS();
        if (br.m_enable_masking)
        {
            for (int i = 0; i < n; ++i)
            {
                cb.DrawMesh(m, t, m_mask_materials[i], i, 0);
                cb.DrawMesh(m, t, m_mask_materials[i], i, 1);
                cb.DrawMesh(m, t, m_mask_materials[i], i, 2);
            }
        }
        else
        {
            for (int i = 0; i < n; ++i)
            {
                cb.DrawMesh(m, t, m_mask_materials[i], i, 3);
            }
        }
    }

    public override void IssueDrawCall_GBuffer(SubRenderer br, CommandBuffer cb)
    {

    }
}
