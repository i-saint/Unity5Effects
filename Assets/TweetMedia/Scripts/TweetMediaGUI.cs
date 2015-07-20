using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.UI;

public class TweetMediaGUI : MonoBehaviour
{
    public bool m_begin_auth_on_start = true;

    public TweetMedia m_tweet_media;
    public GameObject m_ui_auth;
    public GameObject m_ui_tweet;
    public UnityEngine.UI.Text m_text_status;
    public UnityEngine.UI.Button m_button_auth_url;
    public UnityEngine.UI.InputField m_input_pin;
    public UnityEngine.UI.Button m_button_pin;
    public UnityEngine.UI.InputField m_input_message;
    public UnityEngine.UI.Button m_button_tweet;
    Action<TweetMedia.AuthStateCode> m_auth_event_handler;
    Action<TweetMedia.TweetStateCode> m_tweet_event_handler;



    string status_text
    {
        get { return m_text_status != null ? m_text_status.text : ""; }
        set { if (m_text_status != null) { m_text_status.text = value; } }
    }

    public virtual void HandleAuthEvent(TweetMedia.AuthStateCode code)
    {
        switch(code)
        {
            case TweetMedia.AuthStateCode.VerifyCredentialsBegin:
                status_text = "";
                m_ui_auth.SetActive(false);
                m_ui_tweet.SetActive(false);
                break;
            case TweetMedia.AuthStateCode.VerifyCredentialsSucceeded:
                m_ui_tweet.SetActive(true);
                break;
            case TweetMedia.AuthStateCode.VerifyCredentialsFailed:
                m_ui_auth.SetActive(true);
                break;

            case TweetMedia.AuthStateCode.RequestAuthURLBegin:
                m_input_pin.text = "";
                m_button_auth_url.interactable = false;
                m_input_pin.interactable = false;
                m_button_pin.interactable = false;
                break;
            case TweetMedia.AuthStateCode.RequestAuthURLSucceeded:
                m_button_auth_url.interactable = true;
                m_input_pin.interactable = true;
                m_button_pin.interactable = true;
                break;
            case TweetMedia.AuthStateCode.RequestAuthURLFailed:
                status_text = m_tweet_media.error_message;
                break;

            case TweetMedia.AuthStateCode.EnterPINBegin:
                status_text = "";
                break;
            case TweetMedia.AuthStateCode.EnterPINSucceeded:
                m_ui_auth.SetActive(false);
                m_ui_tweet.SetActive(true);
                break;
            case TweetMedia.AuthStateCode.EnterPINFailed:
                status_text = m_tweet_media.error_message;
                break;
        }
    }

    public virtual void OnMessageUpdated()
    {
        status_text = m_input_message.text.Length.ToString() + " char";
    }


    public virtual void Start()
    {
        m_tweet_media.AddAuthEventHandler(HandleAuthEvent);
        m_tweet_media.AddTweetEventHandler(HandleTweetEvent);
        if (m_begin_auth_on_start)
        {
            BeginAuthorization();
        }
    }

    public virtual void BeginAuthorization()
    {
        m_tweet_media.BeginAuthorize();
    }

    public virtual void OpenAuthURL()
    {
        Application.OpenURL(m_tweet_media.auth_url);
    }

    public virtual void EnterPin()
    {
        m_tweet_media.pin = m_input_pin.text;
    }


    public virtual void HandleTweetEvent(TweetMedia.TweetStateCode code)
    {
        switch (code)
        {
            case TweetMedia.TweetStateCode.Begin:
                status_text = "Tweet in progress...";
                m_input_message.interactable = false;
                m_button_tweet.interactable = false;
                break;
            case TweetMedia.TweetStateCode.Succeeded:
                m_input_message.text = "";
                status_text = "Succeeded!";
                m_input_message.interactable = true;
                m_button_tweet.interactable = true;
                break;
            case TweetMedia.TweetStateCode.Failed:
                status_text = "Failed: " + m_tweet_media.error_message;
                m_input_message.interactable = true;
                m_button_tweet.interactable = true;
                break;
        }
    }

    public virtual void BeginTweet()
    {
        m_tweet_media.BeginTweet(m_input_message.text);
    }
}
