using System.Collections;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Ist
{
    [ExecuteInEditMode]
    public class BezierPatchEditor : IBezierPatchContainer
    {
        [SerializeField] BezierPatch m_bpatch = new BezierPatch();
        [SerializeField] bool m_lock;
        [SerializeField] Transform[] m_cpobj;
        [SerializeField] Mesh m_mesh;
        BezierPatchRaw[] m_bpatch_raw;
        BezierPatchAABB[] m_aabb;

        public override BezierPatchRaw[] GetBezierPatches()
        {
            if(m_bpatch_raw == null)
            {
                m_bpatch_raw = new BezierPatchRaw[1];
            }
            m_bpatch.GetRawData(ref m_bpatch_raw[0]);
            return m_bpatch_raw;
        }

        public override BezierPatchAABB[] GetAABBs()
        {
            if (m_aabb == null)
            {
                m_aabb = new BezierPatchAABB[1];
            }
            m_bpatch.GetAABB(ref m_aabb[0]);
            return m_aabb;
        }


        public BezierPatch bpatch { get { return m_bpatch; } }
    
        public void UpdatePreviewMesh()
        {
            const int div = 16;
            const int divsq = div * div;
            bool update_indices = false;
    
            if (m_mesh ==null)
            {
                update_indices = true;
    
                GameObject go = new GameObject();
                go.name = "Bezier Patch Mesh";
                go.GetComponent<Transform>().SetParent(GetComponent<Transform>());
    
                var mesh_filter = go.AddComponent<MeshFilter>();
                var mesh_renderer = go.AddComponent<MeshRenderer>();
#if UNITY_EDITOR
                mesh_renderer.sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Examples/Materials/Default.mat");
#endif

                m_mesh = new Mesh();
                mesh_filter.sharedMesh = m_mesh;
            }
    
            // update vertices
            {
                var vertices = new Vector3[divsq];
                var normals = new Vector3[divsq];
                var span = new Vector2(1.0f / (div - 1), 1.0f / (div - 1));
    
                for (int y = 0; y < div; ++y)
                {
                    for (int x = 0; x < div; ++x)
                    {
                        int i = y * div + x;
                        var uv = new Vector2(span.x * x, span.y * y);
                        vertices[i] = m_bpatch.Evaluate(uv);
                        normals[i] = m_bpatch.EvaluateNormal(uv);
                    }
                }
                m_mesh.vertices = vertices;
                m_mesh.normals = normals;
    
                if(update_indices)
                {
                    var indices = new int[divsq * 6];
                    for (int y = 0; y < div - 1; ++y)
                    {
                        for (int x = 0; x < div - 1; ++x)
                        {
                            indices[(y * div + x) * 6 + 0] = (y + 0) * div + (x + 0);
                            indices[(y * div + x) * 6 + 1] = (y + 1) * div + (x + 0);
                            indices[(y * div + x) * 6 + 2] = (y + 1) * div + (x + 1);
    
                            indices[(y * div + x) * 6 + 3] = (y + 0) * div + (x + 0);
                            indices[(y * div + x) * 6 + 4] = (y + 1) * div + (x + 1);
                            indices[(y * div + x) * 6 + 5] = (y + 0) * div + (x + 1);
                        }
                    }
                    m_mesh.SetIndices(indices, MeshTopology.Triangles, 0);
                }
            }
        }
    
        void DestroyControlPoints()
        {
            if (m_cpobj != null)
            {
                for (int i = 0; i < m_cpobj.Length; ++i)
                {
                    if(m_cpobj[i] != null)
                    {
                        DestroyImmediate(m_cpobj[i].gameObject);
                    }
                }
                m_cpobj = null;
            }
        }
    
        void ConstructControlPoints()
        {
            if (m_cpobj == null || m_cpobj.Length != 16)
            {
                m_cpobj = new Transform[16];

                var trans = GetComponent<Transform>();
                for (int y = 0; y < 4; ++y)
                {
                    for (int x = 0; x < 4; ++x)
                    {
                        int i = y * 4 + x;
                        if (m_cpobj[i] == null)
                        {
                            var go = new GameObject();
                            go.name = "Control Point [" + y + "][" + x + "]";
                            go.AddComponent<BezierPatchControlPoint>();
                            var t = go.GetComponent<Transform>();
                            t.position = m_bpatch.cp[i];
                            t.SetParent(trans);
                            m_cpobj[i] = t;
                        }
                    }
                }
            }
        }
    
    
        void OnDestroy()
        {
            DestroyControlPoints();
        }
    
        void Update()
        {
            if(m_lock)
            {
                DestroyControlPoints();
            }
            else
            {
                ConstructControlPoints();
                for (int i = 0; i < m_bpatch.cp.Length; ++i)
                {
                    m_bpatch.cp[i] = m_cpobj[i].localPosition;
                }
                UpdatePreviewMesh();
            }
        }

        void OnDrawGizmos()
        {
            Gizmos.color = Color.cyan;
            for (int y = 0; y < 4; ++y)
            {
                for (int x = 0; x < 3; ++x)
                {
                    Gizmos.DrawLine(m_cpobj[y*4 + x].position, m_cpobj[y*4 + x+1].position);
                }
            }
            for (int y = 0; y < 3; ++y)
            {
                for (int x = 0; x < 4; ++x)
                {
                    Gizmos.DrawLine(m_cpobj[y * 4 + x].position, m_cpobj[(y+1) * 4 + x].position);
                }
            }
        }
    }
}
