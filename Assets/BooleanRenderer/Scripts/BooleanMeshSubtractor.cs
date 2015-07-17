using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/MeshSubtractor")]
[RequireComponent(typeof(MeshFilter))]
public class BooleanMeshSubtractor : IBooleanSubtractor
{
    public Material[] m_materials;
    public Material m_material_stencil;
    Transform m_trans;
    MeshFilter m_mesh;

#if UNITY_EDITOR
    void Reset()
    {
        m_materials = new Material[] {
            AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtractor.mat"),
        };
        m_material_stencil = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/StencilMask.mat");
    }
#endif // UNITY_EDITOR

    void Start()
    {
        m_trans = GetComponent<Transform>();
        m_mesh = GetComponent<MeshFilter>();
    }

    public override void IssueDrawCall_GBuffer(CommandBuffer cb)
    {
        Mesh mesh = m_mesh.sharedMesh;
        Matrix4x4 trans = m_trans.localToWorldMatrix;

        cb.DrawMesh(mesh, trans, m_material_stencil, 0, 0);
        foreach (var material in m_materials)
        {
            cb.DrawMesh(mesh, trans, material);
        }
        cb.DrawMesh(mesh, trans, m_material_stencil, 0, 1);
    }

    void OnDrawGizmos()
    {
        var mesh = GetComponent<MeshFilter>().sharedMesh;
        if (mesh != null)
        {
            Gizmos.matrix = GetComponent<Transform>().localToWorldMatrix;
            Gizmos.DrawMesh(mesh);
        }
    }
}
