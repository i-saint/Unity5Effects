using UnityEngine;
using System.Collections;

[RequireComponent(typeof(GUIText))]
public class FrameRateCounter : MonoBehaviour
{
    public float m_update_interval = 0.5f;
    private float m_last_time;
    private float m_accum = 0.0f; // FPS accumulated over the interval
    private int m_frames = 0; // Frames drawn over the interval
    private float m_time_left; // Left time for current interval
    private float m_result;

    void Start()
    {
        m_time_left = m_update_interval;
        m_last_time = Time.realtimeSinceStartup;
    }

    void Update()
    {
        float now = Time.realtimeSinceStartup;
        float delta = now - m_last_time;
        m_last_time = now;
        m_time_left -= delta;
        m_accum += 1.0f / delta;
        ++m_frames;

        // Interval ended - update result
        if (m_time_left <= 0.0)
        {
            m_result = m_accum / m_frames;
            GetComponent<GUIText>().text = m_result.ToString("f2");
            m_time_left = m_update_interval;
            m_accum = 0.0f;
            m_frames = 0;
        }
    }
}
