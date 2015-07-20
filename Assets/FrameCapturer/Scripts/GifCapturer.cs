using System;
using System.Collections;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("FrameCapturer/GifCapturer")]
[RequireComponent(typeof(Camera))]
public class GifCapturer : MovieCapturer
{
    public int m_resolution_width = 300;
    public int m_num_colors = 255;
    public int m_capture_every_n_frames = 2;
    public int m_interval_centi_sec = 3;
    public int m_max_frame = 1800;
    public int m_max_data_size = 0;
    public int m_max_active_tasks = 0;
    public int m_keyframe = 0;
    public Shader m_sh_copy;

    IntPtr m_gif;
    Material m_mat_copy;
    Mesh m_quad;
    CommandBuffer m_cb;
    RenderTexture m_scratch_buffer;
    Camera m_cam;
    int m_frame;
    bool m_recode = false;

    GifCapturer()
    {
        // Plugins/* を dll サーチパスに追加
        try { FrameCapturer.AddLibraryPath(); } catch { }
    }

    public override bool recode
    {
        get { return m_recode; }
        set { m_recode = value; }
    }

    public override void WriteFile(string path = "", int begin_frame = 0, int end_frame = -1)
    {
        if (m_gif != IntPtr.Zero)
        {
            if (path.Length==0)
            {
                path = DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".gif";
            }
            FrameCapturer.fcGifWriteFile(m_gif, path, begin_frame, end_frame);
            print("GifCapturer.WriteFile() : " + path);
        }
    }

    public override void WriteMemory(System.IntPtr dst_buf, int begin_frame = 0, int end_frame = -1)
    {
        if (m_gif != IntPtr.Zero)
        {
            FrameCapturer.fcGifWriteMemory(m_gif, dst_buf, begin_frame, end_frame);
            print("GifCapturer.WriteMemry()");
        }
    }

    public override RenderTexture GetScratchBuffer() { return m_scratch_buffer; }

    public override void ResetRecordingState()
    {
        FrameCapturer.fcGifDestroyContext(m_gif);
        m_gif = IntPtr.Zero;
        if(m_scratch_buffer != null)
        {
            m_scratch_buffer.Release();
            m_scratch_buffer = null;
        }

        int capture_width = m_resolution_width;
        int capture_height = (int)(m_resolution_width / ((float)m_cam.pixelWidth / (float)m_cam.pixelHeight));
        m_scratch_buffer = new RenderTexture(capture_width, capture_height, 0, RenderTextureFormat.ARGB32);
        m_scratch_buffer.wrapMode = TextureWrapMode.Repeat;
        m_scratch_buffer.Create();

        m_frame = 0;
        if (m_max_active_tasks <= 0)
        {
            m_max_active_tasks = SystemInfo.processorCount;
        }
        FrameCapturer.fcGifConfig conf;
        conf.width = m_scratch_buffer.width;
        conf.height = m_scratch_buffer.height;
        conf.num_colors = m_num_colors;
        conf.delay_csec = m_interval_centi_sec;
        conf.keyframe = m_keyframe;
        conf.max_frame = m_max_frame;
        conf.max_data_size = m_max_data_size;
        conf.max_active_tasks = m_max_active_tasks;
        m_gif = FrameCapturer.fcGifCreateContext(ref conf);
    }

    public override void EraseFrame(int begin_frame, int end_frame)
    {
        FrameCapturer.fcGifEraseFrame(m_gif, begin_frame, end_frame);
    }

    public override int GetExpectedFileSize(int begin_frame = 0, int end_frame = -1)
    {
        return FrameCapturer.fcGifGetExpectedDataSize(m_gif, begin_frame, end_frame);
    }

    public override int GetFrameCount()
    {
        return FrameCapturer.fcGifGetFrameCount(m_gif);
    }

    public override void GetFrameData(RenderTexture rt, int frame)
    {
        FrameCapturer.fcGifGetFrameData(m_gif, rt.GetNativeTexturePtr(), frame);
    }

    public IntPtr GetGifContext() { return m_gif; }

#if UNITY_EDITOR
    void Reset()
    {
        m_sh_copy = AssetDatabase.LoadAssetAtPath("Assets/FrameCapturer/Shaders/CopyFrameBuffer.shader", typeof(Shader)) as Shader;
    }

    void OnValidate()
    {
        m_num_colors = Mathf.Clamp(m_num_colors, 1, 255);
    }
#endif // UNITY_EDITOR

    void OnEnable()
    {
        m_cam = GetComponent<Camera>();
        m_quad = FrameCapturerUtils.CreateFullscreenQuad();
        m_mat_copy = new Material(m_sh_copy);
        if (m_cam.targetTexture != null)
        {
            m_mat_copy.EnableKeyword("OFFSCREEN");
        }

        {
            int tid = Shader.PropertyToID("_TmpFrameBuffer");
            m_cb = new CommandBuffer();
            m_cb.name = "GifCapturer: copy frame buffer";
            m_cb.GetTemporaryRT(tid, -1, -1, 0, FilterMode.Point);
            m_cb.Blit(BuiltinRenderTextureType.CurrentActive, tid);
            // tid は意図的に開放しない
            m_cam.AddCommandBuffer(CameraEvent.AfterEverything, m_cb);
        }
        ResetRecordingState();
    }

    void OnDisable()
    {
        FrameCapturer.fcGifDestroyContext(m_gif);
        m_gif = IntPtr.Zero;

        m_cam.RemoveCommandBuffer(CameraEvent.AfterEverything, m_cb);
        m_cb.Release();
        m_cb = null;

        m_scratch_buffer.Release();
        m_scratch_buffer = null;
    }

    IEnumerator OnPostRender()
    {
        if (m_recode)
        {
            yield return new WaitForEndOfFrame();

            int frame = m_frame++;
            if (frame % m_capture_every_n_frames == 0)
            {
                m_mat_copy.SetPass(0);
                Graphics.SetRenderTarget(m_scratch_buffer);
                Graphics.DrawMeshNow(m_quad, Matrix4x4.identity);
                Graphics.SetRenderTarget(null);
                FrameCapturer.fcGifAddFrame(m_gif, m_scratch_buffer.GetNativeTexturePtr());
            }
        }
    }
}
