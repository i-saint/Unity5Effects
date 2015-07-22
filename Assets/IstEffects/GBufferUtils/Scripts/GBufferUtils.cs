using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    [RequireComponent(typeof(Camera))]
    //[ExecuteInEditMode]
    public class GBufferUtils : MonoBehaviour
    {
        public bool m_enable_inv_matrices;
        public bool m_enable_prev_albedo;
        public bool m_enable_prev_specular;
        public bool m_enable_prev_normal;
        public bool m_enable_prev_emission;
        public bool m_enable_prev_depth;
        public Shader m_sh_gbuffer_copy;
        public Mesh m_quad;
        Material m_mat_gbuffer_copy;
        Matrix4x4 m_vp;
        Matrix4x4 m_inv_vp;
        Matrix4x4 m_prev_vp;
        Matrix4x4 m_prev_inv_vp;
        CommandBuffer m_cb_framebuffer;
        RenderTexture[] m_gbuffer_rt = new RenderTexture[4];
        RenderTexture m_depth;
        RenderBuffer[] m_gbuffer_rb = new RenderBuffer[4];


        public Matrix4x4 matrix_vp { get { return m_vp; } }
        public Matrix4x4 matrix_inv_vp { get { return m_inv_vp; } }
        public Matrix4x4 matrix_prev_vp { get { return m_prev_vp; } }
        public Matrix4x4 matrix_prev_inv_vp { get { return m_prev_inv_vp; } }

        public RenderTexture gbuffer_prev_albedo { get { return m_gbuffer_rt[0]; } }
        public RenderTexture gbuffer_prev_specular { get { return m_gbuffer_rt[1]; } }
        public RenderTexture gbuffer_prev_normal { get { return m_gbuffer_rt[2]; } }
        public RenderTexture gbuffer_prev_emission { get { return m_gbuffer_rt[3]; } }
        public RenderTexture gbuffer_prev_depth { get { return m_depth; } }

        public bool prev_color_buffers_enabled
        { get { return m_enable_prev_albedo || m_enable_prev_specular || m_enable_prev_normal || m_enable_prev_emission; } }

#if UNITY_EDITOR
        void Reset()
        {
            m_sh_gbuffer_copy = AssetDatabase.LoadAssetAtPath("Assets/IstEffects/GBufferUtils/Shaders/GBufferCopy.shader", typeof(Shader)) as Shader;
            m_quad = GenerateQuad();
        }
#endif // UNITY_EDITOR


        void OnDestroy()
        {
            for (int i = 0; i < m_gbuffer_rt.Length; ++i)
            {
                if (m_gbuffer_rt[i] != null)
                {
                    m_gbuffer_rt[i].Release();
                    m_gbuffer_rt[i] = null;
                }
            }
            if (m_depth != null)
            {
                m_depth.Release();
                m_depth = null;
            }
        }

        void OnDisable()
        {
            var cam = GetComponent<Camera>();
            if (m_cb_framebuffer != null)
            {
                cam.RemoveCommandBuffer(CameraEvent.AfterSkybox, m_cb_framebuffer);
                m_cb_framebuffer.Release();
                m_cb_framebuffer = null;
            }
        }

        void OnPreRender()
        {
            var act = gameObject.activeInHierarchy && enabled;
            if (!act) return;

            var cam = GetComponent<Camera>();

            if (m_enable_inv_matrices)
            {
                Matrix4x4 view = cam.worldToCameraMatrix;
                Matrix4x4 proj = cam.projectionMatrix;
                // Unity internally modify projection matrix like this.
                // GL.GetGPUProjectionMatrix() seems doing similar things, but it is different on some (OpenGL etc) platforms. 
                proj[2, 0] = proj[2, 0] * 0.5f + proj[3, 0] * 0.5f;
                proj[2, 1] = proj[2, 1] * 0.5f + proj[3, 1] * 0.5f;
                proj[2, 2] = proj[2, 2] * 0.5f + proj[3, 2] * 0.5f;
                proj[2, 3] = proj[2, 3] * 0.5f + proj[3, 3] * 0.5f;
                m_prev_vp = m_vp;
                m_prev_inv_vp = m_inv_vp;
                m_vp = proj * view;
                m_inv_vp = m_vp.inverse;
                Shader.SetGlobalMatrix("_InvViewProj", m_inv_vp);
                Shader.SetGlobalMatrix("_PrevViewProj", m_prev_vp);
                Shader.SetGlobalMatrix("_PrevInvViewProj", m_prev_inv_vp);
            }

            if (prev_color_buffers_enabled)
            {
                if (m_gbuffer_rt[0] != null)
                {
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture0", m_gbuffer_rt[0]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture1", m_gbuffer_rt[1]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture2", m_gbuffer_rt[2]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture3", m_gbuffer_rt[3]);
                }
            }
            if (m_enable_prev_depth)
            {
                if (m_depth != null)
                {
                    Shader.SetGlobalTexture("_PrevCameraDepthTexture", m_depth);
                }
            }
        }


        RenderTexture CreateGBufferRT(RenderTextureFormat format)
        {
            var cam = GetComponent<Camera>();
            var ret = new RenderTexture(cam.pixelWidth, cam.pixelHeight, 0, format);
            ret.filterMode = FilterMode.Point;
            ret.useMipMap = false;
            ret.generateMips = false;
            ret.Create();
            return ret;
        }

        IEnumerator OnPostRender()
        {
            yield return new WaitForEndOfFrame();

            var cam = GetComponent<Camera>();

            if (prev_color_buffers_enabled)
            {
                if (m_mat_gbuffer_copy == null)
                {
                    m_mat_gbuffer_copy = new Material(m_sh_gbuffer_copy);
                }
                if (m_gbuffer_rt[0] == null)
                {
                    m_gbuffer_rt[0] = CreateGBufferRT(RenderTextureFormat.ARGB32);
                    m_gbuffer_rt[1] = CreateGBufferRT(RenderTextureFormat.ARGB32);
                    m_gbuffer_rt[2] = CreateGBufferRT(RenderTextureFormat.ARGB2101010);
                    m_gbuffer_rt[3] = CreateGBufferRT(cam.hdr ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32);
                    m_gbuffer_rb[0] = m_gbuffer_rt[0].colorBuffer;
                    m_gbuffer_rb[1] = m_gbuffer_rt[1].colorBuffer;
                    m_gbuffer_rb[2] = m_gbuffer_rt[2].colorBuffer;
                    m_gbuffer_rb[3] = m_gbuffer_rt[3].colorBuffer;
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture0", m_gbuffer_rt[0]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture1", m_gbuffer_rt[1]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture2", m_gbuffer_rt[2]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture3", m_gbuffer_rt[3]);
                }

                m_mat_gbuffer_copy.SetPass(0);
                Graphics.SetRenderTarget(m_gbuffer_rb, m_gbuffer_rt[0].depthBuffer);
                Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);
                Graphics.SetRenderTarget(null);
            }

            if (m_enable_prev_depth)
            {
                if (m_mat_gbuffer_copy == null)
                {
                    m_mat_gbuffer_copy = new Material(m_sh_gbuffer_copy);
                }
                if (m_depth == null)
                {
                    m_depth = CreateGBufferRT(RenderTextureFormat.RFloat);
                    Shader.SetGlobalTexture("_PrevCameraDepthTexture", m_depth);
                }

                m_mat_gbuffer_copy.SetPass(1);
                Graphics.SetRenderTarget(m_depth);
                Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);
                Graphics.SetRenderTarget(null);
            }
        }

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
            r.name = "Quad";
            r.vertices = vertices;
            r.triangles = indices;
            return r;
        }
    }
}