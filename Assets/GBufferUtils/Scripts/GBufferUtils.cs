using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(Camera))]
//[ExecuteInEditMode]
public class GBufferUtils : MonoBehaviour
{
    public bool m_enable_inv_matrices;
    public bool m_enable_prev_gbuffer;
    public Shader m_sh_gbuffer_copy;
    public Mesh m_quad;
    Material m_mat_gbuffer_copy;
    Matrix4x4 m_vp;
    Matrix4x4 m_inv_vp;
    Matrix4x4 m_prev_vp;
    Matrix4x4 m_prev_inv_vp;
    CommandBuffer m_cb_framebuffer;
    public RenderTexture[] m_gbuffer_rt = new RenderTexture[5];
    RenderBuffer[] m_gbuffer_rb = new RenderBuffer[5];


    public Matrix4x4 vp { get { return m_vp; } }
    public Matrix4x4 inv_vp { get { return m_inv_vp; } }
    public Matrix4x4 prev_vp { get { return m_prev_vp; } }
    public Matrix4x4 prev_inv_vp { get { return m_prev_inv_vp; } }



#if UNITY_EDITOR
    void Reset()
    {
        m_sh_gbuffer_copy = AssetDatabase.LoadAssetAtPath("Assets/GBufferUtils/Shaders/GBufferCopy.shader", typeof(Shader)) as Shader;
        m_quad = GenerateQuad();
    }
#endif // UNITY_EDITOR


    void OnDestroy()
    {
        for (int i = 0; i < m_gbuffer_rt.Length; ++i )
        {
            if (m_gbuffer_rt[i] != null)
            {
                m_gbuffer_rt[i].Release();
                m_gbuffer_rt[i] = null;
            }
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

        if(m_enable_inv_matrices)
        {
            Matrix4x4 view = cam.worldToCameraMatrix;
            Matrix4x4 proj = cam.projectionMatrix;
            // Unity internally modify projection matrix like this.
            // (GL.GetGPUProjectionMatrix() maybe better solution)
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

        if (m_enable_prev_gbuffer)
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
                m_gbuffer_rt[4] = CreateGBufferRT(RenderTextureFormat.RFloat);
                for (int i = 0; i < m_gbuffer_rt.Length; ++i)
                {
                    m_gbuffer_rb[i] = m_gbuffer_rt[i].colorBuffer;
                }

                Shader.SetGlobalTexture("_PrevCameraGBufferTexture0", m_gbuffer_rt[0]);
                Shader.SetGlobalTexture("_PrevCameraGBufferTexture1", m_gbuffer_rt[1]);
                Shader.SetGlobalTexture("_PrevCameraGBufferTexture2", m_gbuffer_rt[2]);
                Shader.SetGlobalTexture("_PrevCameraGBufferTexture3", m_gbuffer_rt[3]);
                Shader.SetGlobalTexture("_PrevCameraDepthTexture", m_gbuffer_rt[4]);
            }
            m_mat_gbuffer_copy.SetPass(0);
            Graphics.SetRenderTarget(m_gbuffer_rb, m_gbuffer_rt[0].depthBuffer);
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
