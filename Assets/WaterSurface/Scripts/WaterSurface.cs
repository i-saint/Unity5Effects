using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif


[RequireComponent(typeof(Camera))]
[RequireComponent(typeof(FrameBufferUtils))]
public class WaterSurface : MonoBehaviour
{
    public float m_speed = 1.00f;
    public float m_refraction = 0.05f;
    public float m_reflection_intensity = 0.3f;
    public float m_fresnel = 0.25f;
    public float m_raymarch_step = 0.2f;
    public float m_attenuation_by_distance = 0.02f;
    public Shader m_shader;
    Material m_material;
    CommandBuffer m_cb;
    CameraEvent m_timing = CameraEvent.AfterSkybox;


#if UNITY_EDITOR
    void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath("Assets/WaterSurface/Shaders/WaterSurface.shader", typeof(Shader)) as Shader;
        GetComponent<FrameBufferUtils>().m_enable_inv_matrices = true;
        GetComponent<FrameBufferUtils>().m_enable_frame_buffer = true;
    }
#endif // UNITY_EDITOR

    void OnEnable()
    {
    }

    void OnDisable()
    {
        ReleaseCommandBuffer();
    }

    void Awake()
    {
        m_material = new Material(m_shader);
    }


    void ReleaseCommandBuffer()
    {
        if (m_cb != null)
        {
            GetComponent<Camera>().RemoveCommandBuffer(m_timing, m_cb);
            m_cb.Release();
            m_cb = null;
        }
    }


    void OnPreRender()
    {
        if (m_cb == null)
        {
            m_cb = new CommandBuffer();
            m_cb.name = "WaterSurface";
            GetComponent<Camera>().AddCommandBuffer(m_timing, m_cb);
        }

        m_cb.Clear();
        WaterSurfaceField.instances.ForEach((e) =>
        {
            m_cb.DrawMesh(e.GetMesh(), e.GetMatrix(), m_material);
        });

        Camera cam = GetComponent<Camera>();
        Matrix4x4 proj = cam.projectionMatrix;
        Matrix4x4 view = cam.worldToCameraMatrix;
        proj[2, 0] = proj[2, 0] * 0.5f + proj[3, 0] * 0.5f;
        proj[2, 1] = proj[2, 1] * 0.5f + proj[3, 1] * 0.5f;
        proj[2, 2] = proj[2, 2] * 0.5f + proj[3, 2] * 0.5f;
        proj[2, 3] = proj[2, 3] * 0.5f + proj[3, 3] * 0.5f;
        var viewProj = proj * view;
        var viewProjInv = viewProj.inverse;

        m_material.SetMatrix("_InvViewProj", viewProjInv);
        m_material.SetFloat("g_speed", m_speed);
        m_material.SetFloat("g_refraction", m_refraction);
        m_material.SetFloat("g_reflection_intensity", m_reflection_intensity);
        m_material.SetFloat("g_fresnel", m_fresnel);
        m_material.SetFloat("g_raymarch_step", m_raymarch_step);
        m_material.SetFloat("g_attenuation_by_distance", m_attenuation_by_distance);
    }
}


public class EffectUtils
{
    public static RenderTexture CreateRenderTexture(int w, int h, int d, RenderTextureFormat f)
    {
        Debug.Log("EffectsUtil.CreateRenderTexture() " + w + ", " + h + ", " + d);
        RenderTexture r = new RenderTexture(w, h, d, f);
        r.filterMode = FilterMode.Point;
        r.useMipMap = false;
        r.generateMips = false;
        r.enableRandomWrite = true;
        //r.wrapMode = TextureWrapMode.Repeat;
        r.Create();
        return r;
    }
}
