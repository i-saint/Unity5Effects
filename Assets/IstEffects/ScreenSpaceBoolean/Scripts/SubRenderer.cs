using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


namespace Ist
{
    [AddComponentMenu("IstEffects/ScreenSpaceBoolean/SubRenderer")]
    [ExecuteInEditMode]
    public class SubRenderer : MonoBehaviour
    {
        public bool m_enable_masking = true;
        public bool m_enable_piercing = true;

        public Mesh m_quad;
        public Shader m_sh_composite;

        Material m_mat_composite;
        CommandBuffer m_commands;
        List<Camera> m_cameras = new List<Camera>();


        public static Mesh GenerateQuad()
        {
            Vector3[] vertices = new Vector3[4] {
                new Vector3( 1.0f, 1.0f, 0.0f),
                new Vector3(-1.0f, 1.0f, 0.0f),
                new Vector3(-1.0f,-1.0f, 0.0f),
                new Vector3( 1.0f,-1.0f, 0.0f),
            };
            int[] indices = new int[6] { 0, 1, 2, 2, 3, 0 };

            Mesh r = new Mesh();
            r.vertices = vertices;
            r.triangles = indices;
            return r;
        }

#if UNITY_EDITOR
        void Reset()
        {
            m_quad = GenerateQuad();
            m_sh_composite = AssetDatabase.LoadAssetAtPath<Shader>("Assets/IstEffects/ScreenSpaceBoolean/Shaders/CompositeSub.shader");
        }
#endif // UNITY_EDITOR

        void OnDestroy()
        {
            Object.DestroyImmediate(m_mat_composite);
        }

        void OnDisable()
        {
            if (m_commands != null)
            {
                int c = m_cameras.Count;
                for (int i = 0; i < c; ++i)
                {
                    if (m_cameras[i] != null)
                    {
                        m_cameras[i].RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
                    }
                }
                m_cameras.Clear();
            }
        }

        void OnPreRender()
        {
            if (!gameObject.activeInHierarchy && !enabled) { return; }

            var cam = GetComponent<Camera>();

            UpdateCommandBuffer();

            if (!m_cameras.Contains(cam))
            {
                cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
                m_cameras.Add(cam);
            }
        }

        void OnWillRenderObject()
        {
            if (!gameObject.activeInHierarchy && !enabled) { return; }

            var cam = Camera.current;
            if (!cam) { return; }

            UpdateCommandBuffer();

            if (!m_cameras.Contains(cam))
            {
                cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
                m_cameras.Add(cam);
            }
        }

        void UpdateCommandBuffer()
        {
            if (m_commands == null)
            {
                m_commands = new CommandBuffer();
                m_commands.name = "SubtractionRenderer";
                m_mat_composite = new Material(m_sh_composite);
            }

            m_commands.Clear();
            var greceivers = ISubReceiver.GetGroups();
            var goperators = ISubOperator.GetGroups();
            foreach (var v in greceivers)
            {
                var operators = goperators.ContainsKey(v.Key) ? goperators[v.Key] : null;
                IssueDrawcalls_Depth(v.Value, operators);
            }
        }

        void IssueDrawcalls_Depth(HashSet<ISubReceiver> receivers, HashSet<ISubOperator> operaors)
        {
            int id_backdepth = Shader.PropertyToID("BackDepth");
            int id_tmpdepth = Shader.PropertyToID("TmpDepth");

            // render back depth if piercing enabled
            if (m_enable_piercing)
            {
                m_commands.GetTemporaryRT(id_backdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
                m_commands.SetRenderTarget(id_backdepth);
                m_commands.ClearRenderTarget(true, true, Color.black, 0.0f);
                foreach (var reseiver in receivers)
                {
                    if (reseiver != null)
                    {
                        reseiver.IssueDrawCall_BackDepth(this, m_commands);
                    }
                }
                m_commands.SetGlobalTexture("_BackDepth", id_backdepth);
            }

            m_commands.GetTemporaryRT(id_tmpdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
            m_commands.SetRenderTarget(id_tmpdepth);
            m_commands.ClearRenderTarget(true, true, Color.black, 1.0f);
            foreach (var reseiver in receivers)
            {
                if (reseiver != null)
                {
                    reseiver.IssueDrawCall_FrontDepth(this, m_commands);
                }
            }
            if (operaors != null)
            {
                foreach (var op in operaors)
                {
                    if (op != null)
                    {
                        op.IssueDrawCall_DepthMask(this, m_commands);
                    }
                }
            }

            m_commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
            m_commands.SetGlobalTexture("_TmpDepth", id_tmpdepth);
            m_commands.DrawMesh(m_quad, Matrix4x4.identity, m_mat_composite);
        }
    }
}