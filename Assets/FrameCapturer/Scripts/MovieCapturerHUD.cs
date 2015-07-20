using System.Collections;
using UnityEngine;
using UnityEngine.UI;


public class MovieCapturerHUD : MonoBehaviour
{
    public MovieCapturer m_capturer;
    public Text m_text_info;
    public RawImage m_gif_preview;
    public Slider m_timeslider;
    public InputField m_field_current_frame;
    public RenderTexture m_gif_image;
    int m_current_frame = 0;
    int m_begin_frame = 0;
    int m_end_frame = -1;
    bool m_update_status;
    bool m_update_preview;


    public int begin_frame
    {
        get { return m_begin_frame; }
    }

    public int end_frame
    {
        get { return m_end_frame; }
    }

    public int current_frame
    {
        get { return m_current_frame; }
    }


    public bool recode
    {
        get { return m_capturer.recode; }
        set {
            m_capturer.recode = value;
            m_update_status = true;
            if (value)
            {
                GetComponent<Image>().color = new Color(1.0f, 0.5f, 0.5f, 0.5f);
                UpdatePreviewImage(m_capturer.GetScratchBuffer());
            }
            else
            {
                GetComponent<Image>().color = new Color(1.0f, 1.0f, 1.0f, 0.5f);
                m_end_frame = -1;
            }
        }
    }

    public void WriteFile()
    {
        m_capturer.WriteFile("", m_begin_frame, m_end_frame);
    }

    public void ResetRecordingState()
    {
        m_capturer.ResetRecordingState();
        if(recode)
        {
            UpdatePreviewImage(m_capturer.GetScratchBuffer());
        }
        m_update_status = true;
    }


    public void SetFrameSeek(float v)
    {
        m_current_frame = (int)v;
        m_update_status = true;
        m_update_preview = true;
        m_field_current_frame.text = v.ToString();
    }

    public void SetBeginFrame()
    {
        m_begin_frame = m_current_frame;
        if (m_end_frame >= 0)
        {
            m_end_frame = Mathf.Max(m_end_frame, m_begin_frame);
        }
        m_update_status = true;
    }

    public void SetEndFrame()
    {
        m_end_frame = m_current_frame;
        m_begin_frame = Mathf.Min(m_end_frame, m_begin_frame);
        m_update_status = true;
    }

    public void EraseFrame()
    {
        if (m_end_frame >= 0)
        {
            m_capturer.EraseFrame(m_begin_frame, m_end_frame);
            m_begin_frame = 0;
            m_end_frame = -1;
            m_update_status = true;
        }
    }



    void UpdatePreviewImage(RenderTexture rt)
    {
        const float MaxXScale = 1.8f;
        m_gif_preview.texture = rt;
        float s = (float)rt.width / (float)rt.height;
        float xs = Mathf.Min(s, MaxXScale);
        float ys = MaxXScale / s;
        m_gif_preview.rectTransform.localScale = new Vector3(xs, ys, 1.0f);
    }


    void OnEnable()
    {

    }

    void OnDisable()
    {
        if (m_gif_image != null)
        {
            m_gif_image.Release();
            m_gif_image = null;
        }
    }

    void Update()
    {
        if (m_gif_image == null)
        {
            var gif = m_capturer.GetScratchBuffer();
            m_gif_image = new RenderTexture(gif.width, gif.height, 0, RenderTextureFormat.ARGB32);
            m_gif_image.wrapMode = TextureWrapMode.Repeat;
            m_gif_image.Create();
        }
        if (m_update_preview)
        {
            m_update_preview = false;
            m_capturer.GetFrameData(m_gif_image, m_current_frame);
            UpdatePreviewImage(m_gif_image);
        }
        if(m_update_status || recode)
        {
            m_update_status = false;
            int recoded_frames = m_capturer.GetFrameCount();
            m_timeslider.maxValue = recoded_frames;
            int begin_frame = m_begin_frame;
            int end_frame = m_end_frame == -1 ? recoded_frames : m_end_frame;
            int frame_count = end_frame - begin_frame;
            m_text_info.text =
                recoded_frames.ToString() + " recoded frames\n" +
                frame_count.ToString() + " output frames (" + begin_frame + " - " + end_frame + ")\n" +
                "expected file size: " + m_capturer.GetExpectedFileSize(begin_frame, end_frame);
        }
    }
}
