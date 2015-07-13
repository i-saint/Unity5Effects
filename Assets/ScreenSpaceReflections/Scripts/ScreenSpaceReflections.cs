using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(Camera))]
[RequireComponent(typeof(FrameBufferUtils))]
public class ScreenSpaceReflections : MonoBehaviour
{
    public enum Algorithm
    {
        SinglePass,
        Temporal,
    }
    public enum Quality
    {
        Low,
        Medium,
        High,
    }

    public Algorithm m_algorithm = Algorithm.Temporal;
    public Quality m_quality = Quality.Medium;
    [Range(0.1f, 1.0f)]
    public float m_resolution_scale = 0.5f;
    [Range(0.0f, 2.0f)]
    public float m_intensity = 1.0f;
    [Range(0.0f, 1.0f)]
    public float m_ray_diffusion = 0.01f;

    public float m_raymarch_distance = 5.0f;
    public float m_falloff_distance = 5.0f;
    public float m_object_thickness = 0.4f;
    public float m_max_accumulation = 25.0f;
    public Shader m_shader;

    Material m_material;
    Mesh m_quad;
    RenderTexture[] m_reflection_buffers = new RenderTexture[2];
    RenderTexture[] m_accumulation_buffers = new RenderTexture[2];
    RenderBuffer[] m_rb = new RenderBuffer[2];


#if UNITY_EDITOR
    void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath("Assets/ScreenSpaceReflections/Shaders/ScreenSpaceReflections.shader", typeof(Shader)) as Shader;
    }
#endif // UNITY_EDITOR

    void OnDisable()
    {
        ReleaseRenderTargets();
    }

    void ReleaseRenderTargets()
    {
        for (int i = 0; i < m_reflection_buffers.Length; ++i)
        {
            if (m_reflection_buffers[i] != null)
            {
                m_reflection_buffers[i].Release();
                m_reflection_buffers[i] = null;
            }
            if (m_accumulation_buffers[i] != null)
            {
                m_accumulation_buffers[i].Release();
                m_accumulation_buffers[i] = null;
            }
        }
    }

    void UpdateRenderTargets()
    {
        Camera cam = GetComponent<Camera>();

        Vector2 reso = new Vector2(cam.pixelWidth, cam.pixelHeight) * m_resolution_scale;
        if (m_reflection_buffers[0] != null && m_reflection_buffers[0].width != (int)reso.x)
        {
            ReleaseRenderTargets();
        }
        if (m_reflection_buffers[0] == null || !m_reflection_buffers[0].IsCreated())
        {
            for (int i = 0; i < m_reflection_buffers.Length; ++i)
            {
                m_reflection_buffers[i] = EffectUtils.CreateRenderTexture((int)reso.x, (int)reso.y, 0, RenderTextureFormat.ARGB32);
                m_reflection_buffers[i].filterMode = FilterMode.Point;
                Graphics.SetRenderTarget(m_reflection_buffers[i]);
                GL.Clear(false, true, Color.black);

                m_accumulation_buffers[i] = EffectUtils.CreateRenderTexture((int)reso.x, (int)reso.y, 0, RenderTextureFormat.R8);
                m_accumulation_buffers[i].filterMode = FilterMode.Point;
                Graphics.SetRenderTarget(m_accumulation_buffers[i]);
                GL.Clear(false, true, Color.black);
            }
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (m_material == null)
        {
            m_material = new Material(m_shader);
            m_material.hideFlags = HideFlags.DontSave;

            m_quad = FrameBufferUtils.GenerateQuad();
        }
        UpdateRenderTargets();
        
        switch (m_algorithm)
        {
            case Algorithm.SinglePass:
                m_material.EnableKeyword("ALGORITHM_SIMGLE_PASS");
                break;
            case Algorithm.Temporal:
                m_material.EnableKeyword("ALGORITHM_TEMPORAL");
                break;
        }
        switch (m_quality)
        {
            case Quality.Low:
                m_material.EnableKeyword("QUALITY_LOW");
                break;
            case Quality.Medium:
                m_material.EnableKeyword("QUALITY_MEDIUM");
                break;
            case Quality.High:
                m_material.EnableKeyword("QUALITY_HIGH");
                break;
        }

        m_reflection_buffers[1].filterMode = FilterMode.Point;
        m_material.SetVector("_Params0", new Vector4(m_intensity, m_raymarch_distance, m_ray_diffusion, m_falloff_distance));
        m_material.SetVector("_Params1", new Vector4(m_max_accumulation, m_object_thickness, 0.0f, 0.0f));
        m_material.SetTexture("_ReflectionBuffer", m_reflection_buffers[1]);
        m_material.SetTexture("_AccumulationBuffer", m_accumulation_buffers[1]);
        m_material.SetTexture("_FrameBuffer1", src);

        m_rb[0] = m_reflection_buffers[0].colorBuffer;
        m_rb[1] = m_accumulation_buffers[0].colorBuffer;
        Graphics.SetRenderTarget(m_rb, m_reflection_buffers[0].depthBuffer);
        m_material.SetPass(0);
        Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

        m_reflection_buffers[0].filterMode = FilterMode.Bilinear;
        Graphics.SetRenderTarget(dst);
        m_material.SetTexture("_ReflectionBuffer", m_reflection_buffers[0]);
        m_material.SetTexture("_AccumulationBuffer", m_accumulation_buffers[0]);
        m_material.SetPass(1);
        Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

        Swap(ref m_reflection_buffers[0], ref m_reflection_buffers[1]);
        Swap(ref m_accumulation_buffers[0], ref m_accumulation_buffers[1]);
    }

    public static void Swap<T>(ref T lhs, ref T rhs)
    {
        T tmp;
        tmp = lhs;
        lhs = rhs;
        rhs = tmp;
    }
}
