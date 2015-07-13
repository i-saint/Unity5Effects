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
    public float m_resolution_scale = 0.5f;
    public float m_intensity = 0.3f;
    public float m_raymarch_distance = 0.2f;
    public float m_ray_diffusion = 0.01f;
    public float m_falloff_distance = 20.0f;
    public float m_max_accumulation = 25.0f;
    public Shader m_shader;

    Material m_material;
    Mesh m_quad;
    public RenderTexture[] m_rt_tmp = new RenderTexture[2];


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
        for (int i = 0; i < m_rt_tmp.Length; ++i)
        {
            if (m_rt_tmp[i] != null)
            {
                m_rt_tmp[i].Release();
                m_rt_tmp[i] = null;
            }
        }
    }

    void UpdateRenderTargets()
    {
        Camera cam = GetComponent<Camera>();

        Vector2 reso = new Vector2(cam.pixelWidth, cam.pixelHeight) * m_resolution_scale;
        if (m_rt_tmp[0] != null && m_rt_tmp[0].width != (int)reso.x)
        {
            ReleaseRenderTargets();
        }
        if (m_rt_tmp[0] == null || !m_rt_tmp[0].IsCreated())
        {
            for (int i = 0; i < m_rt_tmp.Length; ++i)
            {
                m_rt_tmp[i] = EffectUtils.CreateRenderTexture((int)reso.x, (int)reso.y, 0, RenderTextureFormat.ARGBHalf);
                m_rt_tmp[i].filterMode = FilterMode.Point;
                Graphics.SetRenderTarget(m_rt_tmp[i]);
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

        m_rt_tmp[1].filterMode = FilterMode.Point;
        m_material.SetFloat("_Intensity", m_intensity);
        m_material.SetFloat("_RayMarchDistance", m_raymarch_distance);
        m_material.SetFloat("_RayDiffusion", m_ray_diffusion);
        m_material.SetFloat("_FalloffDistance", m_falloff_distance);
        m_material.SetFloat("_MaxAccumulation", m_max_accumulation);
        m_material.SetTexture("_PrevResult", m_rt_tmp[1]);
        m_material.SetTexture("_FrameBuffer1", src);

        Graphics.SetRenderTarget(m_rt_tmp[0]);
        m_material.SetPass(0);
        Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

        m_rt_tmp[0].filterMode = FilterMode.Bilinear;
        Graphics.SetRenderTarget(dst);
        m_material.SetTexture("_ReflectionBuffer", m_rt_tmp[0]);
        m_material.SetPass(1);
        Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);
        Swap(ref m_rt_tmp[0], ref m_rt_tmp[1]);
    }

    public static void Swap<T>(ref T lhs, ref T rhs)
    {
        T tmp;
        tmp = lhs;
        lhs = rhs;
        rhs = tmp;
    }
}
