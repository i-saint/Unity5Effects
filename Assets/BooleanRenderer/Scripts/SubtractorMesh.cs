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
public class SubtractorMesh : ISubtractor
{
    public Material m_mat_mask;

#if UNITY_EDITOR
    void Reset()
    {
        var renderer = GetComponent<MeshRenderer>();
        renderer.material = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtractor.mat");
        m_mat_mask = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/StencilMask.mat");
    }
#endif // UNITY_EDITOR

    Mesh mesh { get { return GetComponent<MeshFilter>().sharedMesh; } }
    Matrix4x4 trs { get { return GetComponent<Transform>().localToWorldMatrix; } }

    public override void IssueDrawCall_DepthMask(SubtractionRenderer br, CommandBuffer cb)
    {
        if (br.m_enable_piercing)
        {
            m_mat_mask.EnableKeyword("ENABLE_PIERCING");
        }
        else
        {
            m_mat_mask.DisableKeyword("ENABLE_PIERCING");
        }

        Mesh m = mesh;
        Matrix4x4 trans = trs;
        if (br.m_enable_masking)
        {
            cb.DrawMesh(m, trans, m_mat_mask, 0, 0);
            cb.DrawMesh(m, trans, m_mat_mask, 0, 1);
            cb.DrawMesh(m, trans, m_mat_mask, 0, 2);
        }
        else
        {
            cb.DrawMesh(m, trans, m_mat_mask, 0, 3);
        }
    }
}
