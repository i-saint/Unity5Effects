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
public class BooleanMeshSubtracted : IBooleanSubtracted
{
    public Material m_material_backdepth;
    Transform m_trans;
    MeshFilter m_mesh;

#if UNITY_EDITOR
    void Reset()
    {
        var renderer = GetComponent<MeshRenderer>();
        renderer.material = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/Default_Subtracted.mat");
        m_material_backdepth = AssetDatabase.LoadAssetAtPath<Material>("Assets/BooleanRenderer/Materials/BackDepth.mat");
    }
#endif // UNITY_EDITOR

    void Start()
    {
        m_trans = GetComponent<Transform>();
        m_mesh = GetComponent<MeshFilter>();
        //GetComponent<MeshRenderer>().enabled = false;
    }

    void Update()
    {
        //var renderer = GetComponent<MeshRenderer>();
        //Graphics.DrawMesh(m_mesh.sharedMesh, m_trans.localToWorldMatrix, renderer.material, 0);
    }

    public override void IssueDrawCall_BackDepth(CommandBuffer cb)
    {
        cb.DrawMesh(m_mesh.sharedMesh, m_trans.localToWorldMatrix, m_material_backdepth);
    }

    public override void IssueDrawCall_GBuffer(CommandBuffer cb)
    {
        // do nothing in here.
        // MeshRenderer do the job.
    }
}
