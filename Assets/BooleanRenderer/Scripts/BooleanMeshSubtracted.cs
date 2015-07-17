using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/MeshSubtracted")]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class BooleanMeshSubtracted : IBooleanSubtracted
{
    public Material m_mat_depth;
    Transform m_trans;
    MeshFilter m_mesh;

#if UNITY_EDITOR
    void Reset()
    {
        var renderer = GetComponent<MeshRenderer>();
        renderer.material = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtracted.mat");
        m_mat_depth = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Depth.mat");
    }
#endif // UNITY_EDITOR

    void Start()
    {
        m_trans = GetComponent<Transform>();
        m_mesh = GetComponent<MeshFilter>();
    }

    public override void IssueDrawCall_BackDepth(CommandBuffer cb)
    {
        cb.DrawMesh(m_mesh.sharedMesh, m_trans.localToWorldMatrix, m_mat_depth, 0, 3);
    }

    public override void IssueDrawCall_DepthMask(CommandBuffer cb)
    {
        cb.DrawMesh(m_mesh.sharedMesh, m_trans.localToWorldMatrix, m_mat_depth, 0, 0);
    }
}
