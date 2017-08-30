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
    [ExecuteInEditMode]
    public class GBufferUtils : MonoBehaviour
    {
        public enum VelocityGeneration
        {
            DepthToVelocity,
            VelocityDrawer,
        }

        public bool m_enable_inv_matrices;
        public bool m_enable_prev_albedo;
        public bool m_enable_prev_specular;
        public bool m_enable_prev_normal;
        public bool m_enable_prev_emission;
        public bool m_enable_prev_depth;
        public bool m_enable_velocity;
        public VelocityGeneration m_velocity_generation;
        public bool m_enable_uav;

        public Shader m_sh_gbuffer_copy;
        public Shader m_sh_depth_to_velocity;
        public Mesh m_quad;

        Camera m_camera;
        Material m_mat_gbuffer_copy;
        Material m_mat_depth_to_velocity;
        Matrix4x4 m_view;
        Matrix4x4 m_proj;
        Matrix4x4 m_viewproj;
        Matrix4x4 m_inv_viewproj;
        Matrix4x4 m_prev_view;
        Matrix4x4 m_prev_proj;
        Matrix4x4 m_prev_viewproj;
        Matrix4x4 m_prev_inv_viewproj;
        RenderTexture[] m_rt_gbuffer = new RenderTexture[4];
        RenderTexture m_rt_depth;
        RenderTexture m_rt_velocity;
        public RenderTexture m_rt_continuity;
        RenderBuffer[] m_rb_gbuffer = new RenderBuffer[4];
        RenderBuffer[] m_rb_aux = new RenderBuffer[2];
        bool m_dirty_velocity;

        public Camera GetCamera() { return m_camera; }

        public Matrix4x4 GetMatrix_VP()         { return m_viewproj; }
        public Matrix4x4 GetMatrix_InvVP()      { return m_inv_viewproj; }
        public Matrix4x4 GetMatrix_PrevVP()     { return m_prev_viewproj; }
        public Matrix4x4 GetMatrix_PrevInvVP()  { return m_prev_inv_viewproj; }

        public RenderTexture GetGBuffer_Albedo() { return m_rt_gbuffer[0]; }
        public RenderTexture GetGBuffer_Specular() { return m_rt_gbuffer[1]; }
        public RenderTexture GetGBuffer_Normal() { return m_rt_gbuffer[2]; }
        public RenderTexture GetGBuffer_Emission() { return m_rt_gbuffer[3]; }
        public RenderTexture GetGBuffer_Depth() { return m_rt_depth; }

        public bool prev_gbuffer_required
        { get { return m_enable_prev_albedo || m_enable_prev_specular || m_enable_prev_normal || m_enable_prev_emission || m_enable_prev_depth; } }


        RenderTexture CreateGBufferRT(RenderTextureFormat format, int depth = 0)
        {
            var ret = new RenderTexture(m_camera.pixelWidth, m_camera.pixelHeight, depth, format);
            ret.filterMode = FilterMode.Point;
            ret.useMipMap = false;
            ret.autoGenerateMips = false;
            ret.enableRandomWrite = m_enable_uav;
            ret.Create();
            return ret;
        }

        void UpdatePrevMatrices()
        {
            m_prev_view = m_view;
            m_prev_proj = m_proj;
            m_view = m_camera.worldToCameraMatrix;
            m_proj = GL.GetGPUProjectionMatrix(m_camera.projectionMatrix, false);
            m_prev_viewproj = m_viewproj;
            m_prev_inv_viewproj = m_inv_viewproj;
            m_viewproj = m_proj * m_view;
            m_inv_viewproj = m_viewproj.inverse;

            Shader.SetGlobalMatrix("_InvViewProj", m_inv_viewproj);
            Shader.SetGlobalMatrix("_PrevView", m_prev_view);
            Shader.SetGlobalMatrix("_PrevProj", m_prev_proj);
            Shader.SetGlobalMatrix("_PrevViewProj", m_prev_viewproj);
            Shader.SetGlobalMatrix("_PrevInvViewProj", m_prev_inv_viewproj);
        }


        void UpdatePrevGBuffer()
        {
            if (!prev_gbuffer_required) { return; }

            if (m_mat_gbuffer_copy == null)
            {
                m_mat_gbuffer_copy = new Material(m_sh_gbuffer_copy);
            }
            if (m_rt_gbuffer[0] == null)
            {
                m_rt_gbuffer[0] = CreateGBufferRT(RenderTextureFormat.ARGB32);
                m_rt_gbuffer[1] = CreateGBufferRT(RenderTextureFormat.ARGB32);
                m_rt_gbuffer[2] = CreateGBufferRT(m_enable_uav ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB2101010);
                m_rt_gbuffer[3] = CreateGBufferRT(m_camera.hdr ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32);
                for (int i = 0; i < m_rt_gbuffer.Length; ++i) { m_rb_gbuffer[i] = m_rt_gbuffer[i].colorBuffer; }
                m_rt_depth = CreateGBufferRT(RenderTextureFormat.Depth, 24);
            }

            m_mat_gbuffer_copy.SetPass(0);
            Graphics.SetRenderTarget(m_rb_gbuffer, m_rt_depth.depthBuffer);
            Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

            // this is needed to show stats, frame debugger view, etc.
            Graphics.SetRenderTarget(null);
        }

        public void UpdateVelocityBuffer()
        {
            if(!m_enable_velocity || !m_dirty_velocity) { return; }

            m_dirty_velocity = false;
            if (m_mat_depth_to_velocity == null)
            {
                m_mat_depth_to_velocity = new Material(m_sh_depth_to_velocity);
            }
            if (m_rt_velocity == null)
            {
                m_rt_velocity = CreateGBufferRT(RenderTextureFormat.ARGBHalf);
                m_rt_continuity = CreateGBufferRT(RenderTextureFormat.ARGB32);
                m_rb_aux[0] = m_rt_velocity.colorBuffer;
                m_rb_aux[1] = m_rt_continuity.colorBuffer;
            }

            m_mat_depth_to_velocity.SetPass(0);
            Graphics.SetRenderTarget(m_rb_aux, m_rt_velocity.depthBuffer);
            Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);
            Shader.SetGlobalTexture("_VelocityBuffer", m_rt_velocity);
            Shader.SetGlobalTexture("_ContinuityBuffer", m_rt_continuity);
        }



#if UNITY_EDITOR
        void Reset()
        {
            m_sh_gbuffer_copy = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/GBufferUtils/Shaders/GBufferCopy.shader");
            m_sh_depth_to_velocity = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/GBufferUtils/Shaders/DepthToVelocity.shader");
            m_quad = MeshUtils.GenerateQuad();
        }
#endif // UNITY_EDITOR


        void OnDestroy()
        {
        }

        void OnEnable()
        {
            m_camera = GetComponent<Camera>();
        }

        void OnDisable()
        {
        }

        void OnPreRender()
        {
            var act = gameObject.activeInHierarchy && enabled;
            if (!act) return;

            UpdatePrevMatrices();

            if (prev_gbuffer_required)
            {
                if (m_rt_gbuffer[0] != null)
                {
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture0", m_rt_gbuffer[0]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture1", m_rt_gbuffer[1]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture2", m_rt_gbuffer[2]);
                    Shader.SetGlobalTexture("_PrevCameraGBufferTexture3", m_rt_gbuffer[3]);
                    Shader.SetGlobalTexture("_PrevCameraDepthTexture", m_rt_depth);
                }
            }
            m_dirty_velocity = true;
        }

        IEnumerator OnPostRender()
        {
            yield return new WaitForEndOfFrame();
            UpdatePrevGBuffer();
        }
    }
}