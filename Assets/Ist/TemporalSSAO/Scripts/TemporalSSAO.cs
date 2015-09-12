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
        [Range(1,8)]
        public int m_downsampling = 2;
        public float m_ao_radius = 0.5f;
        public float m_ao_pow = 1.0f;
        public float m_blue_size = 1.0f;

        public Shader m_shader;

        Material m_material;
        Mesh m_quad;
        public RenderTexture[] m_ao_buffer = new RenderTexture[2];


        public static RenderTexture CreateRenderTexture(int w, int h, int d, RenderTextureFormat f)
        {
            RenderTexture r = new RenderTexture(w, h, d, f);
            r.filterMode = FilterMode.Point;
            r.useMipMap = false;
            r.generateMips = false;
            r.Create();
            return r;
        }

#if UNITY_EDITOR
        void Reset()
        {
            m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/TemporalSSAO/Shaders/TemporalSSAO.shader");
            GetComponent<GBufferUtils>().m_enable_inv_matrices = true;
            GetComponent<GBufferUtils>().m_enable_prev_depth = true;
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
                    m_ao_buffer[i].filterMode = FilterMode.Point;
                    Graphics.SetRenderTarget(m_ao_buffer[i]);
                    GL.Clear(false, true, Color.black);
                }
            }
        }

        [ImageEffectOpaque]
        void OnRenderImage(RenderTexture src, RenderTexture dst)
        {
            if (m_material == null)
            {
                m_material = new Material(m_shader);
                m_material.hideFlags = HideFlags.DontSave;

                m_quad = MeshUtils.GenerateQuad();
            }
            UpdateRenderTargets();

            m_ao_buffer[1].filterMode = FilterMode.Point;
            m_material.SetVector("_Params0", new Vector4(m_ao_pow, m_ao_radius, 0.0f, 0.0f));
            m_material.SetTexture("_AOBuffer", m_ao_buffer[1]);
            m_material.SetTexture("_MainTex", src);

            // accumulate ao
            Graphics.SetRenderTarget(m_ao_buffer[0]);
            m_material.SetPass(0);
            Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

            var tmp1 = RenderTexture.GetTemporary(m_ao_buffer[0].width, m_ao_buffer[0].height, 0, RenderTextureFormat.RHalf);
            var tmp2 = RenderTexture.GetTemporary(m_ao_buffer[0].width, m_ao_buffer[0].height, 0, RenderTextureFormat.RHalf);
            tmp1.filterMode = FilterMode.Bilinear;
            tmp2.filterMode = FilterMode.Bilinear;

            // horizontal blur
            m_ao_buffer[0].filterMode = FilterMode.Bilinear;
            Graphics.SetRenderTarget(tmp1);
            m_material.SetTexture("_AOBuffer", m_ao_buffer[0]);
            m_material.SetVector("_BlurOffsetScale", new Vector4(m_blue_size / src.width, 0.0f, 0.0f, 0.0f));
            m_material.SetPass(1);
            Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

            // vertical blur
            m_ao_buffer[0].filterMode = FilterMode.Bilinear;
            Graphics.SetRenderTarget(tmp2);
            m_material.SetTexture("_AOBuffer", tmp1);
            m_material.SetVector("_BlurOffsetScale", new Vector4(0.0f, m_blue_size / src.height, 0.0f, 0.0f));
            m_material.SetPass(1);
            Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);

            // combine
            Graphics.SetRenderTarget(dst);
            m_material.SetTexture("_AOBuffer", tmp2);
            m_material.SetPass(2);
            Graphics.Blit(src, dst, m_material, 1);

            RenderTexture.ReleaseTemporary(tmp2);
            RenderTexture.ReleaseTemporary(tmp1);

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
