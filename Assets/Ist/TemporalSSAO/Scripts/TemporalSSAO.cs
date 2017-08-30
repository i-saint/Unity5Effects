using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    [AddComponentMenu("Ist/Temporal SSAO")]
    [RequireComponent(typeof(Camera))]
    [RequireComponent(typeof(GBufferUtils))]
    [ExecuteInEditMode]
    public class TemporalSSAO : MonoBehaviour
    {
        public enum SampleCount
        {
            Low,
            Medium,
            High,
        }
        public enum DebugOption
        {
            Off,
            ShowAO,
            ShowVelocity,
            ShowViewNormal,
        }

        public SampleCount m_sample_count = SampleCount.Medium;
        [Range(1,8)]
        public int m_downsampling = 3;
        [Range(0.0f, 5.0f)]
        public float m_radius = 0.25f;
        [Range(0.0f, 8.0f)]
        public float m_intensity = 1.5f;
        [Range(0.0f, 8.0f)]
        public float m_blur_size = 0.5f;
        public bool m_dangerous_samples = true;
        public float m_max_accumulation = 100.0f;

#if UNITY_EDITOR
        public DebugOption m_debug_option;
#endif

        public Shader m_shader;

        Material m_material;
        Mesh m_quad;
        RenderTexture[] m_ao_buffer = new RenderTexture[2];


        public static RenderTexture CreateRenderTexture(int w, int h, int d, RenderTextureFormat f)
        {
            RenderTexture r = new RenderTexture(w, h, d, f);
            r.filterMode = FilterMode.Point;
            r.useMipMap = false;
            r.autoGenerateMips = false;
            r.wrapMode = TextureWrapMode.Clamp;
            r.Create();
            return r;
        }

#if UNITY_EDITOR
        void Reset()
        {
            m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/TemporalSSAO/Shaders/TemporalSSAO.shader");
            var gbu = GetComponent<GBufferUtils>();
            gbu.m_enable_inv_matrices = true;
            gbu.m_enable_prev_depth = true;
            gbu.m_enable_velocity = true;
        }
#endif // UNITY_EDITOR

        void Awake()
        {
#if UNITY_EDITOR
            var cam = GetComponent<Camera>();
            if (cam.renderingPath != RenderingPath.DeferredShading &&
                (cam.renderingPath == RenderingPath.UsePlayerSettings && PlayerSettings.renderingPath != RenderingPath.DeferredShading))
            {
                Debug.Log("ScreenSpaceReflections: Rendering path must be deferred.");
            }
#endif // UNITY_EDITOR
        }

        void OnDestroy()
        {
            Object.DestroyImmediate(m_material);
        }

        void OnDisable()
        {
            ReleaseRenderTargets();
        }

        void ReleaseRenderTargets()
        {
            for (int i = 0; i < m_ao_buffer.Length; ++i)
            {
                if (m_ao_buffer[i] != null)
                {
                    m_ao_buffer[i].Release();
                    m_ao_buffer[i] = null;
                }
            }
        }

        void UpdateRenderTargets()
        {
            Camera cam = GetComponent<Camera>();

            Vector2 reso = new Vector2(cam.pixelWidth, cam.pixelHeight) / m_downsampling;
            if (m_ao_buffer[0] != null && m_ao_buffer[0].width != (int)reso.x)
            {
                ReleaseRenderTargets();
            }
            if (m_ao_buffer[0] == null || !m_ao_buffer[0].IsCreated())
            {
                for (int i = 0; i < m_ao_buffer.Length; ++i)
                {
                    m_ao_buffer[i] = CreateRenderTexture((int)reso.x, (int)reso.y, 0, RenderTextureFormat.RGHalf);
                    m_ao_buffer[i].filterMode = FilterMode.Bilinear;
                    Graphics.SetRenderTarget(m_ao_buffer[i]);
                    GL.Clear(false, true, Color.black);
                }
            }
        }

        [ImageEffectOpaque]
        void OnRenderImage(RenderTexture src, RenderTexture dst)
        {
            GetComponent<GBufferUtils>().UpdateVelocityBuffer();

            if (m_material == null)
            {
                m_material = new Material(m_shader);
                m_material.hideFlags = HideFlags.DontSave;

                m_quad = MeshUtils.GenerateQuad();
            }
            UpdateRenderTargets();

            switch(m_sample_count)
            {
                case SampleCount.Low:
                    m_material.EnableKeyword("SAMPLES_LOW");
                    m_material.DisableKeyword("SAMPLES_MEDIUM");
                    m_material.DisableKeyword("SAMPLES_HIGH");
                    break;
                case SampleCount.Medium:
                    m_material.DisableKeyword("SAMPLES_LOW");
                    m_material.EnableKeyword("SAMPLES_MEDIUM");
                    m_material.DisableKeyword("SAMPLES_HIGH");
                    break;
                case SampleCount.High:
                    m_material.DisableKeyword("SAMPLES_LOW");
                    m_material.DisableKeyword("SAMPLES_MEDIUM");
                    m_material.EnableKeyword("SAMPLES_HIGH");
                    break;
            }

            if (m_dangerous_samples)
            {
                m_material.EnableKeyword("ENABLE_DANGEROUS_SAMPLES");
            }
            else
            {
                m_material.DisableKeyword("ENABLE_DANGEROUS_SAMPLES");
            }

#if UNITY_EDITOR
            switch (m_debug_option)
            {
                case DebugOption.Off:
                    m_material.EnableKeyword("DEBUG_OFF");
                    m_material.DisableKeyword("DEBUG_SHOW_AO");
                    m_material.DisableKeyword("DEBUG_SHOW_VELOCITY");
                    m_material.DisableKeyword("DEBUG_SHOW_VIEW_NORMAL");
                    break;
                case DebugOption.ShowAO:
                    m_material.DisableKeyword("DEBUG_OFF");
                    m_material.EnableKeyword("DEBUG_SHOW_AO");
                    m_material.DisableKeyword("DEBUG_SHOW_VELOCITY");
                    m_material.DisableKeyword("DEBUG_SHOW_VIEW_NORMAL");
                    break;
                case DebugOption.ShowVelocity:
                    m_material.DisableKeyword("DEBUG_OFF");
                    m_material.DisableKeyword("DEBUG_SHOW_AO");
                    m_material.EnableKeyword("DEBUG_SHOW_VELOCITY");
                    m_material.DisableKeyword("DEBUG_SHOW_VIEW_NORMAL");
                    break;
                case DebugOption.ShowViewNormal:
                    m_material.DisableKeyword("DEBUG_OFF");
                    m_material.DisableKeyword("DEBUG_SHOW_AO");
                    m_material.DisableKeyword("DEBUG_SHOW_VELOCITY");
                    m_material.EnableKeyword("DEBUG_SHOW_VIEW_NORMAL");
                    break;
            }
#endif

            m_material.SetVector("_Params0", new Vector4(m_radius, m_intensity, m_max_accumulation, 0.0f));
            m_material.SetTexture("_AOBuffer", m_ao_buffer[1]);
            m_material.SetTexture("_MainTex", src);

            // accumulate ao
            Graphics.SetRenderTarget(m_ao_buffer[0]);
            m_material.SetPass(0);
            Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

            if(m_blur_size > 0.0f)
            {
                int w = (int)(m_ao_buffer[0].width * 1.0f);
                int h = (int)(m_ao_buffer[0].height * 1.0f);
                var tmp1 = RenderTexture.GetTemporary(w, h, 0, RenderTextureFormat.RGHalf);
                var tmp2 = RenderTexture.GetTemporary(w, h, 0, RenderTextureFormat.RGHalf);
                tmp1.filterMode = FilterMode.Trilinear;
                tmp2.filterMode = FilterMode.Trilinear;

                // horizontal blur
                Graphics.SetRenderTarget(tmp1);
                m_material.SetTexture("_AOBuffer", m_ao_buffer[0]);
                m_material.SetVector("_BlurOffset", new Vector4(m_blur_size / src.width, 0.0f, 0.0f, 0.0f));
                m_material.EnableKeyword("BLUR_HORIZONTAL");
                m_material.SetPass(1);
                Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);
                m_material.DisableKeyword("BLUR_HORIZONTAL");

                // vertical blur
                Graphics.SetRenderTarget(tmp2);
                m_material.SetTexture("_AOBuffer", tmp1);
                m_material.SetVector("_BlurOffset", new Vector4(0.0f, m_blur_size / src.height, 0.0f, 0.0f));
                m_material.EnableKeyword("BLUR_VERTICAL");
                m_material.SetPass(1);
                Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);
                m_material.DisableKeyword("BLUR_VERTICAL");

                // combine
                Graphics.SetRenderTarget(dst);
                m_material.SetTexture("_AOBuffer", tmp2);
                Graphics.Blit(src, dst, m_material, 2);

                RenderTexture.ReleaseTemporary(tmp2);
                RenderTexture.ReleaseTemporary(tmp1);
            }
            else
            {
                // combine
                Graphics.SetRenderTarget(dst);
                m_material.SetTexture("_AOBuffer", m_ao_buffer[0]);
                Graphics.Blit(src, dst, m_material, 2);
            }

            Swap(ref m_ao_buffer[0], ref m_ao_buffer[1]);
        }

        public static void Swap<T>(ref T lhs, ref T rhs)
        {
            T tmp;
            tmp = lhs;
            lhs = rhs;
            rhs = tmp;
        }
    }
}
