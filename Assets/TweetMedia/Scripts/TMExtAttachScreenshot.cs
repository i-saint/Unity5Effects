using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using UnityEngine;

[RequireComponent(typeof(TweetMedia))]
public class TMExtAttachScreenshot : MonoBehaviour
{
    public MovieCapturerHUD m_capturer_hud;
    public UnityEngine.UI.Toggle m_toggle_screenshot;
    TweetMedia m_tweet_media;


    public static TweetMediaPlugin.tmEMediaType GetMediaType(MovieCapturer capturer)
    {
        if (capturer.GetType()==typeof(GifCapturer))
        {
            return TweetMediaPlugin.tmEMediaType.GIF;
        }
        return TweetMediaPlugin.tmEMediaType.Unknown;
    }

    void AttachScreenshot(TweetMedia.TweetStateCode code)
    {
        if (code == TweetMedia.TweetStateCode.Begin)
        {
            if (!m_toggle_screenshot.isOn) { return; }
            m_toggle_screenshot.isOn = false;

            MovieCapturer capturer = m_capturer_hud.m_capturer;
            var mtype = GetMediaType(capturer);
            if (mtype != TweetMediaPlugin.tmEMediaType.Unknown)
            {
                int begin = m_capturer_hud.begin_frame;
                int end = m_capturer_hud.end_frame;
                int data_size = capturer.GetExpectedFileSize(begin, end);
                IntPtr data = Marshal.AllocHGlobal(data_size);
                capturer.WriteMemory(data, begin, end);
                m_tweet_media.AddMedia(data, data_size, mtype);
                Marshal.FreeHGlobal(data);
            }
        }
    }

    void Start()
    {
        if (m_capturer_hud == null)
        {
            Debug.LogError("TMExtAttachScreenshot: m_capturer_hud is null");
        }
        m_tweet_media = GetComponent<TweetMedia>();
        m_tweet_media.AddTweetEventHandler(AttachScreenshot);
    }
}
