using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using UnityEngine;

public class TweetMedia : MonoBehaviour
{
    public enum AuthStateCode
    {
        VerifyCredentialsBegin,
        VerifyCredentialsSucceeded,
        VerifyCredentialsFailed,
        RequestAuthURLBegin,
        RequestAuthURLSucceeded,
        RequestAuthURLFailed,
        EnterPINBegin,
        EnterPINSucceeded,
        EnterPINFailed,
    }

    public enum TweetStateCode
    {
        Begin,
        Succeeded,
        Failed,
    }


    public string m_consumer_key;
    public string m_consumer_secret;
    public string m_path_to_savedata;

    TweetMediaPlugin.tmContext m_ctx;
    List<Action<AuthStateCode>> m_auth_event_handlers = new List<Action<AuthStateCode>>();
    List<Action<TweetStateCode>> m_tweet_event_handlers = new List<Action<TweetStateCode>>();
    string m_auth_url = "";
    string m_error_message = "";
    string m_pin = "";



    public void AddAuthEventHandler(Action<AuthStateCode> act)
    {
        m_auth_event_handlers.Add(act);
    }
    public void RemoveAuthEventHandler(Action<AuthStateCode> act)
    {
        m_auth_event_handlers.Remove(act);
    }

    public void AddTweetEventHandler(Action<TweetStateCode> act)
    {
        m_tweet_event_handlers.Add(act);
    }
    public void RemoveTweetEventHandler(Action<TweetStateCode> act)
    {
        m_tweet_event_handlers.Remove(act);
    }


    public string auth_url
    {
        get { return m_auth_url; }
    }

    public string error_message
    {
        get { return m_error_message; }
    }

    public string pin
    {
        set { m_pin = value; }
    }

    AuthStateCode auth_state
    {
        set
        {
            m_auth_event_handlers.ForEach((h) => { h.Invoke(value); });
        }
    }

    TweetStateCode tweet_state
    {
        set
        {
            m_tweet_event_handlers.ForEach((h) => { h.Invoke(value); });
        }
    }


    public void BeginAuthorize()
    {
        if (m_ctx.ptr != IntPtr.Zero)
        {
            StartCoroutine(Authorize());
        }
    }

    IEnumerator Authorize()
    {
        bool authorized = false;

        // 保存された token が有効かチェック
        auth_state = AuthStateCode.VerifyCredentialsBegin;
        TweetMediaPlugin.tmLoadCredentials(m_ctx, m_path_to_savedata);
        TweetMediaPlugin.tmVerifyCredentialsAsync(m_ctx);
        while (enabled)
        {
            var state = TweetMediaPlugin.tmGetVerifyCredentialsState(m_ctx);
            if (state.code == TweetMediaPlugin.tmEStatusCode.InProgress)
            {
                yield return 0;
            }
            else
            {
                if (state.code == TweetMediaPlugin.tmEStatusCode.Succeeded)
                {
                    authorized = true;
                    auth_state = AuthStateCode.VerifyCredentialsSucceeded;
                }
                else
                {
                    m_error_message = state.error_message;
                    auth_state = AuthStateCode.VerifyCredentialsFailed;
                }
                break;
            }
        }

        // token が無効な場合認証処理開始
        while (enabled && !authorized)
        {
            // 認証 URL を取得
            auth_state = AuthStateCode.RequestAuthURLBegin;
            TweetMediaPlugin.tmRequestAuthURLAsync(m_ctx, m_consumer_key, m_consumer_secret);
            while (enabled)
            {
                var state = TweetMediaPlugin.tmGetRequestAuthURLState(m_ctx);
                if (state.code == TweetMediaPlugin.tmEStatusCode.InProgress)
                {
                    yield return 0;
                }
                else
                {
                    if (state.code == TweetMediaPlugin.tmEStatusCode.Succeeded)
                    {
                        m_auth_url = state.auth_url;
                        auth_state = AuthStateCode.RequestAuthURLSucceeded;
                    }
                    else
                    {
                        m_error_message = state.error_message;
                        auth_state = AuthStateCode.RequestAuthURLFailed;
                        // ここで失敗したらほとんど続けようがない (consumer key / secret が無効かネットワーク障害)
                        yield break;
                    }
                    break;
                }
            }

            // pin の入力を待って送信
            while (enabled && m_pin.Length == 0) { yield return 0; }

            m_error_message = "";
            auth_state = AuthStateCode.EnterPINBegin;
            TweetMediaPlugin.tmEnterPinAsync(m_ctx, m_pin);
            m_pin = "";
            while (enabled)
            {
                var state = TweetMediaPlugin.tmGetEnterPinState(m_ctx);
                if (state.code == TweetMediaPlugin.tmEStatusCode.InProgress)
                {
                    yield return 0;
                }
                else
                {
                    if (state.code == TweetMediaPlugin.tmEStatusCode.Succeeded)
                    {
                        authorized = true;
                        TweetMediaPlugin.tmSaveCredentials(m_ctx, m_path_to_savedata);
                        auth_state = AuthStateCode.EnterPINSucceeded;
                    }
                    else
                    {
                        m_error_message = state.error_message;
                        auth_state = AuthStateCode.EnterPINFailed;
                    }
                    break;
                }
            }

        }
    }




    public void AddMediaFile(string path)
    {
        TweetMediaPlugin.tmAddMediaFile(m_ctx, path);
    }

    public void AddMedia(IntPtr data, int datasize, TweetMediaPlugin.tmEMediaType mtype)
    {
        TweetMediaPlugin.tmAddMedia(m_ctx, data, datasize, mtype);
    }

    public void ClearMedia()
    {
        TweetMediaPlugin.tmClearMedia(m_ctx);
    }

    public void BeginTweet(string message)
    {
        StartCoroutine(Tweet(message));
    }

    IEnumerator Tweet(string message)
    {
        tweet_state = TweetStateCode.Begin;
        int handle = TweetMediaPlugin.tmTweetAsync(m_ctx, message);
        while(enabled) {
            TweetMediaPlugin.tmTweetState state = TweetMediaPlugin.tmGetTweetState(m_ctx, handle);
            if (state.code == TweetMediaPlugin.tmEStatusCode.InProgress)
            {
                yield return 0;
            }
            else
            {
                if (state.code == TweetMediaPlugin.tmEStatusCode.Succeeded)
                {
                    tweet_state = TweetStateCode.Succeeded;
                }
                else
                {
                    m_error_message = state.error_message;
                    tweet_state = TweetStateCode.Failed;
                }
                TweetMediaPlugin.tmReleaseTweetCache(m_ctx, handle);
                break;
            }
        }
    }



    void OnEnable()
    {
        if(m_consumer_key=="" || m_consumer_secret=="")
        {
            Debug.LogError("TweetMedia: set consumer_key and consumer_secret!");
        }
        m_ctx = TweetMediaPlugin.tmCreateContext();
    }

    void OnDisable()
    {
        TweetMediaPlugin.tmDestroyContext(m_ctx);
        m_ctx.Clear();
    }
}
