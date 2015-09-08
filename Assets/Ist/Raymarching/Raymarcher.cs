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

[ExecuteInEditMode]
public class Raymarcher : MonoBehaviour
{
    public Material m_material;
    public bool m_screen_space = true;
    public bool m_enable_adaptive = true;
    public bool m_enable_temporal = true;
    public bool m_enable_glowline = true;
    public bool m_dbg_show_steps;
    public int m_scene;
    public Color m_fog_color = new Color(0.16f, 0.13f, 0.20f);
    Material m_internal_material;
    Vector2 m_resolution_prev;
    Mesh m_quad;

    CommandBuffer m_cb_prepass;
    CommandBuffer m_cb_raymarch;
    CommandBuffer m_cb_show_steps;

    bool m_enable_adaptive_prev;
    bool m_dbg_show_steps_prev;

#if UNITY_EDITOR
    void Reset()
    {
        m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/Raymarching/Raymarcher.mat");
    }
#endif // UNITY_EDITOR

    void Awake()
    {
#if UNITY_EDITOR
        var cam = GetComponent<Camera>();
        if (cam !=null &&
            cam.renderingPath != RenderingPath.DeferredShading &&
            (cam.renderingPath == RenderingPath.UsePlayerSettings && PlayerSettings.renderingPath != RenderingPath.DeferredShading))
        {
            Debug.Log("Raymarcher: Rendering path must be deferred.");
        }
#endif // UNITY_EDITOR

        m_internal_material = new Material(m_material);
        var r = GetComponent<Renderer>();
        if (r != null) { r.sharedMaterial = m_internal_material; }


        m_enable_adaptive_prev = m_enable_adaptive;
    }

    void ClearCommandBuffer()
    {
        var cam = GetComponent<Camera>();
        if (cam != null)
        {
            if (m_cb_prepass != null)
            {
                cam.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_prepass);
            }
            if (m_cb_raymarch != null)
            {
                cam.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_raymarch);
            }
            if (m_cb_show_steps != null)
            {
                cam.RemoveCommandBuffer(CameraEvent.AfterEverything, m_cb_show_steps);
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

    void OnWillRenderObject()
    {
        UpdateMaterial();
    }

    void OnPreRender()
    {
        UpdateMaterial();
        UpdateCommandBuffer();
    }

    void SwitchKeyword(Material m, string name, bool v)
    {
        if(v) { m.EnableKeyword(name); }
        else  { m.DisableKeyword(name); }
    }

    void UpdateMaterial()
    {
        if(m_internal_material == null) { return; }

        m_internal_material.SetFloat("_Scene", m_scene);
        SwitchKeyword(m_internal_material, "ENABLE_ADAPTIVE",    m_enable_adaptive );
        SwitchKeyword(m_internal_material, "ENABLE_TEMPORAL",    m_enable_temporal );
        SwitchKeyword(m_internal_material, "ENABLE_PATTERN",     m_enable_glowline );
        SwitchKeyword(m_internal_material, "ENABLE_SCREENSPACE", m_screen_space    );
        if (!m_screen_space)
        {
            var t = GetComponent<Transform>();
            var r = t.rotation;
            float angle;
            Vector3 axis;
            r.ToAngleAxis(out angle, out axis);
            m_internal_material.SetVector("_Position", t.position);
            m_internal_material.SetVector("_Rotation", new Vector4(axis.x, axis.y, axis.z, angle));
            m_internal_material.SetVector("_Scale", t.lossyScale);
        }
    }

    void UpdateCommandBuffer()
    {
        var cam = GetComponent<Camera>();

        RenderSettings.fogColor = m_fog_color;

        if (m_quad == null)
        {
            m_quad = RaymarcherUtils.GenerateQuad();
        }

        bool reflesh_command_buffer = false;

        Vector2 reso = new Vector2(cam.pixelWidth, cam.pixelHeight);
        if(m_resolution_prev!=reso)
        {
            m_resolution_prev = reso;
            reflesh_command_buffer = true;
        }

        if (m_enable_adaptive_prev != m_enable_adaptive)
        {
            m_enable_adaptive_prev = m_enable_adaptive;
            reflesh_command_buffer = true;
        }
        if (m_dbg_show_steps_prev != m_dbg_show_steps)
        {
            m_dbg_show_steps_prev = m_dbg_show_steps;
            reflesh_command_buffer = true;
        }

        if (reflesh_command_buffer)
        {
            reflesh_command_buffer = false;
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

                m_cb_prepass.GetTemporaryRT(odepth,     cam.pixelWidth / 8, cam.pixelHeight / 8, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(odepth_prev,cam.pixelWidth / 8, cam.pixelHeight / 8, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(ovelocity,  cam.pixelWidth / 8, cam.pixelHeight / 8, 0, FilterMode.Point, RenderTextureFormat.RHalf);
                m_cb_prepass.GetTemporaryRT(qdepth,     cam.pixelWidth / 4, cam.pixelHeight / 4, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(qdepth_prev,cam.pixelWidth / 4, cam.pixelHeight / 4, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(hdepth,     cam.pixelWidth / 2, cam.pixelHeight / 2, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(hdepth_prev,cam.pixelWidth / 2, cam.pixelHeight / 2, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(adepth,     cam.pixelWidth / 1, cam.pixelHeight / 1, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                m_cb_prepass.GetTemporaryRT(adepth_prev,cam.pixelWidth / 1, cam.pixelHeight / 1, 0, FilterMode.Point, RenderTextureFormat.RFloat);

                rt = new RenderTargetIdentifier[2] { odepth, ovelocity };
                m_cb_prepass.SetGlobalTexture("g_depth_prev", odepth_prev);
                m_cb_prepass.SetRenderTarget(rt, odepth);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_internal_material, 0, 1);

                m_cb_prepass.Blit(odepth, odepth_prev);
                m_cb_prepass.SetGlobalTexture("g_velocity", ovelocity);

                m_cb_prepass.SetRenderTarget(qdepth);
                m_cb_prepass.SetGlobalTexture("g_depth", odepth);
                m_cb_prepass.SetGlobalTexture("g_depth_prev", qdepth_prev);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_internal_material, 0, 2);

                m_cb_prepass.Blit(qdepth, qdepth_prev);

                m_cb_prepass.SetRenderTarget(hdepth);
                m_cb_prepass.SetGlobalTexture("g_depth", qdepth);
                m_cb_prepass.SetGlobalTexture("g_depth_prev", hdepth_prev);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_internal_material, 0, 3);

                m_cb_prepass.Blit(hdepth, hdepth_prev);

                m_cb_prepass.SetRenderTarget(adepth);
                m_cb_prepass.SetGlobalTexture("g_depth", hdepth);
                m_cb_prepass.SetGlobalTexture("g_depth_prev", adepth_prev);
                m_cb_prepass.DrawMesh(m_quad, Matrix4x4.identity, m_internal_material, 0, 4);

                m_cb_prepass.Blit(adepth, adepth_prev);
                m_cb_prepass.SetGlobalTexture("g_depth", adepth);

                cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_prepass);
            }

            m_cb_raymarch = new CommandBuffer();
            m_cb_raymarch.name = "Raymarcher";
            m_cb_raymarch.DrawMesh(m_quad, Matrix4x4.identity, m_internal_material, 0, 0);
            cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_raymarch);
        }
    }
}
