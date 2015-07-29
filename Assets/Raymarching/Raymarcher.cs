using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


public static class RaymarcherUtils
{
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

    public static Mesh GenerateDetailedQuad()
    {
        const int div_x = 325;
        const int div_y = 200;

        var cell = new Vector2(2.0f / div_x, 2.0f / div_y);
        var vertices = new Vector3[65000];
        var indices = new int[(div_x-1)*(div_y-1)*6];
        for (int iy = 0; iy < div_y; ++iy)
        {
            for (int ix = 0; ix < div_x; ++ix)
            {
                int i = div_x * iy + ix;
                vertices[i] = new Vector3(cell.x * ix - 1.0f, cell.y * iy - 1.0f, 0.0f);
            }
        }
        for (int iy = 0; iy < div_y-1; ++iy)
        {
            for (int ix = 0; ix < div_x-1; ++ix)
            {
                int i = ((div_x-1) * iy + ix)*6;
                indices[i + 0] = (div_x * (iy + 1)) + (ix + 1);
                indices[i + 1] = (div_x * (iy + 0)) + (ix + 1);
                indices[i + 2] = (div_x * (iy + 0)) + (ix + 0);

                indices[i + 3] = (div_x * (iy + 0)) + (ix + 0);
                indices[i + 4] = (div_x * (iy + 1)) + (ix + 0);
                indices[i + 5] = (div_x * (iy + 1)) + (ix + 1);
            }
        }

        Mesh r = new Mesh();
        r.vertices = vertices;
        r.triangles = indices;
        return r;
    }
}

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class Raymarcher : MonoBehaviour
{
    public Material m_material;
    public bool m_enable_adaptive = true;
    public bool m_enable_temporal = true;
    public bool m_enable_glowline = true;
    public bool m_dbg_show_steps;
    public int m_scene;
    public Color m_fog_color = new Color(0.16f, 0.13f, 0.20f);
    Vector2 m_resolution_prev;
    Mesh m_quad;

    Camera m_camera;
    CommandBuffer m_cb_prepass;
    CommandBuffer m_cb_raymarch;
    CommandBuffer m_cb_show_steps;

    bool m_enable_adaptive_prev;
    bool m_dbg_show_steps_prev;

    void Awake()
    {
        var cam = GetComponent<Camera>();
#if UNITY_EDITOR
        if (cam.renderingPath != RenderingPath.DeferredShading &&
            (cam.renderingPath == RenderingPath.UsePlayerSettings && PlayerSettings.renderingPath != RenderingPath.DeferredShading))
        {
            Debug.Log("Raymarcher: Rendering path must be deferred.");
        }
#endif // UNITY_EDITOR

        m_camera = cam;
        m_enable_adaptive_prev = m_enable_adaptive;
    }

    void ClearCommandBuffer()
    {
        if (m_camera != null)
        {
            if (m_cb_prepass != null)
            {
                m_camera.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_prepass);
            }
            if (m_cb_raymarch != null)
            {
                m_camera.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_raymarch);
            }
            if (m_cb_show_steps != null)
            {
                m_camera.RemoveCommandBuffer(CameraEvent.AfterEverything, m_cb_show_steps);
            }
            m_cb_prepass = null;
            m_cb_raymarch = null;
            m_cb_show_steps = null;
        }
    }

    void OnDisable()
    {
        ClearCommandBuffer();
    }

    void OnPreRender()
    {
        m_material.SetInt("g_hdr", m_camera.hdr ? 1 : 0);
        m_material.SetInt("g_scene", m_scene);
        m_material.SetInt("g_enable_adaptive", m_enable_adaptive ? 1 : 0);
        m_material.SetInt("g_enable_temporal", m_enable_temporal ? 1 : 0);
        m_material.SetInt("g_enable_glowline", m_enable_glowline ? 1 : 0);

        RenderSettings.fogColor = m_fog_color;

        if (m_quad == null)
        {
            m_quad = RaymarcherUtils.GenerateQuad();
        }

        bool need_to_reflesh_command_buffer = false;

        Vector2 reso = new Vector2(m_camera.pixelWidth, m_camera.pixelHeight);
        if(m_resolution_prev!=reso)
        {
            m_resolution_prev = reso;
            need_to_reflesh_command_buffer = true;
        }

        if (m_enable_adaptive_prev != m_enable_adaptive)
        {
            m_enable_adaptive_prev = m_enable_adaptive;
            need_to_reflesh_command_buffer = true;
        }
        if (m_dbg_show_steps_prev != m_dbg_show_steps)
        {
            m_dbg_show_steps_prev = m_dbg_show_steps;
            need_to_reflesh_command_buffer = true;
        }

        if (need_to_reflesh_command_buffer)
        {
            need_to_reflesh_command_buffer = false;
            ClearCommandBuffer();
        }

        if (m_cb_raymarch==null)
        {
            if (m_enable_adaptive)
            {
                RenderTargetIdentifier[] rt;

                m_cb_prepass = new CommandBuffer();
                m_cb_prepass.name = "Raymarcher Adaptive PrePass";

                int odepth      = Shader.PropertyToID("ODepth");
                int odepth_prev = Shader.PropertyToID("ODepthPrev");
                int ovelocity   = Shader.PropertyToID("OVelocity");
                int qdepth      = Shader.PropertyToID("QDepth");
                int qdepth_prev = Shader.PropertyToID("QDepthPrev");
                int hdepth      = Shader.PropertyToID("HDepth");
                int hdepth_prev = Shader.PropertyToID("HDepthPrev");
                int adepth      = Shader.PropertyToID("ADepth");
                int adepth_prev = Shader.PropertyToID("ADepthPrev");

                m_cb_prepass.GetTemporaryRT(odepth,     m_camera.pixelWidth / 8, m_camera.pixelHeight / 8, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(odepth_prev,m_camera.pixelWidth / 8, m_camera.pixelHeight / 8, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(ovelocity,  m_camera.pixelWidth / 8, m_camera.pixelHeight / 8, 0, FilterMode.Point, RenderTextureFormat.RHalf);
                m_cb_prepass.GetTemporaryRT(qdepth,     m_camera.pixelWidth / 4, m_camera.pixelHeight / 4, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(qdepth_prev,m_camera.pixelWidth / 4, m_camera.pixelHeight / 4, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(hdepth,     m_camera.pixelWidth / 2, m_camera.pixelHeight / 2, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(hdepth_prev,m_camera.pixelWidth / 2, m_camera.pixelHeight / 2, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(adepth,     m_camera.pixelWidth / 1, m_camera.pixelHeight / 1, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(adepth_prev,m_camera.pixelWidth / 1, m_camera.pixelHeight / 1, 0, FilterMode.Point, RenderTextureFormat.RFloat);

                rt = new RenderTargetIdentifier[2] { odepth, ovelocity };
                m_cb_prepass.SetGlobalTexture("g_depth_prev", odepth_prev);
                m_cb_prepass.SetRenderTarget(rt, odepth);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_material, 0, 1);

                m_cb_prepass.Blit(odepth, odepth_prev);
                m_cb_prepass.SetGlobalTexture("g_velocity", ovelocity);

                m_cb_prepass.SetRenderTarget(qdepth);
                m_cb_prepass.SetGlobalTexture("g_depth", odepth);
                m_cb_prepass.SetGlobalTexture("g_depth_prev", qdepth_prev);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_material, 0, 2);

                m_cb_prepass.Blit(qdepth, qdepth_prev);

                m_cb_prepass.SetRenderTarget(hdepth);
                m_cb_prepass.SetGlobalTexture("g_depth", qdepth);
                m_cb_prepass.SetGlobalTexture("g_depth_prev", hdepth_prev);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_material, 0, 3);

                m_cb_prepass.Blit(hdepth, hdepth_prev);

                m_cb_prepass.SetRenderTarget(adepth);
                m_cb_prepass.SetGlobalTexture("g_depth", hdepth);
                m_cb_prepass.SetGlobalTexture("g_depth_prev", adepth_prev);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_material, 0, 4);

                m_cb_prepass.Blit(adepth, adepth_prev);
                m_cb_prepass.SetGlobalTexture("g_depth", adepth);

                m_camera.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_prepass);
            }

            m_cb_raymarch = new CommandBuffer();
            m_cb_raymarch.name = "Raymarcher";
            m_cb_raymarch.DrawMesh(m_quad, Matrix4x4.identity, m_material, 0, 0);
            m_camera.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_raymarch);
        }
    }
}
