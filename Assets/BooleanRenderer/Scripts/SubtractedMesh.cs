using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/SubtractedMesh")]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class SubtractedMesh : ISubtracted
{
    public Material m_mat_depth;

#if UNITY_EDITOR
    void Reset()
    {
        var renderer = GetComponent<MeshRenderer>();
        renderer.material = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtracted.mat");
        m_mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Depth.mat");
    }
#endif // UNITY_EDITOR

    Mesh mesh { get { return GetComponent<MeshFilter>().sharedMesh; } }
    Matrix4x4 trs { get { return GetComponent<Transform>().localToWorldMatrix; } }

    public override void IssueDrawCall_BackDepth(SubtractionRenderer br, CommandBuffer cb)
    {
        cb.DrawMesh(mesh, trs, m_mat_depth, 0, 0);
    }

    public override void IssueDrawCall_DepthMask(SubtractionRenderer br, CommandBuffer cb)
    {
        cb.DrawMesh(mesh, trs, m_mat_depth, 0, 1);
    }
}
