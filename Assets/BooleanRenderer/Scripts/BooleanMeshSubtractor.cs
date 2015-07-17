using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/MeshSubtractor")]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class BooleanMeshSubtractor : IBooleanSubtractor
{
    public Material m_mat_mask;
    Transform m_trans;
    MeshFilter m_mesh;

#if UNITY_EDITOR
    void Reset()
    {
        var renderer = GetComponent<MeshRenderer>();
        renderer.material = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtractor.mat");
        m_mat_mask = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/StencilMask.mat");
    }
#endif // UNITY_EDITOR

    void Start()
    {
        m_trans = GetComponent<Transform>();
        m_mesh = GetComponent<MeshFilter>();
    }

    public override void IssueDrawCall_DepthMask(CommandBuffer cb)
    {
        Mesh mesh = m_mesh.sharedMesh;
        Matrix4x4 trans = m_trans.localToWorldMatrix;
        cb.DrawMesh(mesh, trans, m_mat_mask, 0, 0);
        cb.DrawMesh(mesh, trans, m_mat_mask, 0, 1);
        cb.DrawMesh(mesh, trans, m_mat_mask, 0, 2);
    }
}
