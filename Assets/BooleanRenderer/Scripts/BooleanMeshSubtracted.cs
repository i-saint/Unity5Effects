using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/MeshSubtracted")]
[RequireComponent(typeof(MeshFilter))]
public class BooleanMeshSubtracted : IBooleanSubtracted
{
    public Material[] m_materials;
    public Material m_material_backdepth;
    Transform m_trans;
    MeshFilter m_mesh;

#if UNITY_EDITOR
    void Reset()
    {
    }
#endif // UNITY_EDITOR

    void Start()
    {
        m_trans = GetComponent<Transform>();
        m_mesh = GetComponent<MeshFilter>();
    }

    public override void IssueDrawCall_BackDepth(CommandBuffer cb)
    {
        cb.DrawMesh(m_mesh.sharedMesh, m_trans.localToWorldMatrix, m_material_backdepth);
    }

    public override void IssueDrawCall_GBuffer(CommandBuffer cb)
    {
        foreach (var material in m_materials)
        {
            cb.DrawMesh(m_mesh.sharedMesh, m_trans.localToWorldMatrix, material);
        }
    }
}
