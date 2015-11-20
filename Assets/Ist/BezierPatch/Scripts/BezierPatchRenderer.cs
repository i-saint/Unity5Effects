using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif


namespace Ist
{
    [AddComponentMenu("Ist/BezierPatch/BezierPatchRenderer")]
    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    [RequireComponent(typeof(IBezierPatchContainer))]
    [ExecuteInEditMode]
    public class BezierPatchRenderer : ICommandBufferExecuter<BezierPatchRenderer>
    {
        [SerializeField] Mesh m_bound_mesh;
        [SerializeField] Material m_material;
        int m_num_vertices = 0;
        Material m_material_copy; // I need to copy material because MaterialPropertyBlock don't have SetBuffer()
        ComputeBuffer m_buf_vertices;
        ComputeBuffer m_buf_bpatches;
        ComputeBuffer m_buf_aabbs;


#if UNITY_EDITOR
        void Reset()
        {
            m_bound_mesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Foundation/Meshes/Cube.asset");
            m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/BezierPatch/Materials/BezierPatchRaytracer.mat");
            GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Foundation/Meshes/Cube.asset");
            GetComponent<MeshRenderer>().sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/Foundation/Materials/DoNothing.mat");
        }
#endif

        public override void OnDisable()
        {
            base.OnDisable();
            if (m_buf_vertices != null)
            {
                m_buf_vertices.Release();
                m_buf_vertices = null;
            }
            if (m_buf_bpatches != null)
            {
                m_buf_bpatches.Release();
                m_buf_bpatches = null;
            }
            if (m_buf_aabbs != null)
            {
                m_buf_aabbs.Release();
                m_buf_aabbs = null;
            }
        }


        protected override void AddCommandBuffer(Camera cam, CommandBuffer cb)
        {
            cam.AddCommandBuffer(CameraEvent.AfterGBuffer, cb);
        }

        protected override void RemoveCommandBuffer(Camera cam, CommandBuffer cb)
        {
            cam.RemoveCommandBuffer(CameraEvent.AfterGBuffer, cb);
        }

        protected override void UpdateCommandBuffer(CommandBuffer cb)
        {
            cb.Clear();
            foreach (var i in GetInstances()) { i.IssueDrawCall(cb); }
        }

        void IssueDrawCall(CommandBuffer cb)
        {
            if (m_material_copy == null)
            {
                m_material_copy = new Material(m_material);
            }

            var cont = GetComponent<IBezierPatchContainer>();
            var bpatches = cont.GetBezierPatches();
            var aabbs = cont.GetAABBs();
            if (m_buf_vertices == null)
            {
                BatchRendererUtil.CreateVertexBuffer(m_bound_mesh, ref m_buf_vertices, ref m_num_vertices, BatchRendererUtil.VertexFormat.P);
                m_material_copy.SetBuffer("_Vertices", m_buf_vertices);
            }
            if (m_buf_bpatches == null)
            {
                m_buf_bpatches = new ComputeBuffer(bpatches.Length, BezierPatchRaw.size);
                m_material_copy.SetBuffer("_BezierPatches", m_buf_bpatches);
            }
            if (m_buf_aabbs == null)
            {
                m_buf_aabbs = new ComputeBuffer(aabbs.Length, BezierPatchAABB.size);
                m_material_copy.SetBuffer("_AABBs", m_buf_aabbs);
            }
            m_buf_bpatches.SetData(bpatches);
            m_buf_aabbs.SetData(aabbs);

            cb.DrawProcedural(Matrix4x4.identity, m_material_copy, 0, MeshTopology.Triangles, m_num_vertices, bpatches.Length);
        }
    }
}
