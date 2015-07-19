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
    public Material m_mat_depth;
    Mesh m_mesh;

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
        m_mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Depth.mat");
    }
#endif // UNITY_EDITOR

    void LateUpdate()
    {
        GetComponent<SkinnedMeshRenderer>().BakeMesh(GetMesh());
    }

    Mesh GetMesh() {
        if (m_mesh == null) { m_mesh = new Mesh(); }
        return m_mesh;
    }
    Matrix4x4 GetTRS() { return GetComponent<Transform>().localToWorldMatrix; }

    public override void IssueDrawCall_BackDepth(SubRenderer br, CommandBuffer cb)
    {
        cb.DrawMesh(GetMesh(), GetTRS(), m_mat_depth, 0, 0);
    }

    public override void IssueDrawCall_DepthMask(SubRenderer br, CommandBuffer cb)
    {
        cb.DrawMesh(GetMesh(), GetTRS(), m_mat_depth, 0, 1);
    }
}
