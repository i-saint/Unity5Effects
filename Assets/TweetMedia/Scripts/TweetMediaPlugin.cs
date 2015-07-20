using System;
using System.Collections;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using UnityEngine;

public static class TweetMediaPlugin
{
    public struct tmContext
    {
        public IntPtr ptr;
        public void Clear() { ptr = IntPtr.Zero; }
    }

    public enum tmEStatusCode
    {
        Unknown,
        InProgress,
        Failed,
        Succeeded,
    };

    public enum tmEMediaType
    {
        Unknown,
        PNG,
        JPEG,
        GIF,
        WEBP,
        MP4,
    };

    public struct tmAuthState
    {
        public tmEStatusCode code;
        public IntPtr _error_message;   // 
        public IntPtr _auth_url;        // these fields should be private. but then compiler gives warning.
        public string error_message { get { return Marshal.PtrToStringAnsi(_error_message); } }
        public string auth_url { get { return Marshal.PtrToStringAnsi(_auth_url); } }
    };


    public struct tmTweetState
    {
        public tmEStatusCode code;
        public IntPtr _error_message;   // 
        public string error_message { get { return Marshal.PtrToStringAnsi(_error_message); } }
    };


    [DllImport ("TweetMedia")] public static extern tmContext       tmCreateContext();
    [DllImport ("TweetMedia")] public static extern void            tmDestroyContext(tmContext ctx);

    [DllImport ("TweetMedia")] public static extern bool            tmLoadCredentials(tmContext ctx, string path);
    [DllImport ("TweetMedia")] public static extern bool            tmSaveCredentials(tmContext ctx, string path);

    [DllImport ("TweetMedia")] public static extern tmAuthState     tmVerifyCredentials(tmContext ctx);
    [DllImport ("TweetMedia")] public static extern void            tmVerifyCredentialsAsync(tmContext ctx);
    [DllImport ("TweetMedia")] public static extern tmAuthState     tmGetVerifyCredentialsState(tmContext ctx);

    [DllImport ("TweetMedia")] public static extern tmAuthState     tmRequestAuthURL(tmContext ctx, string consumer_key, string consumer_secret);
    [DllImport ("TweetMedia")] public static extern void            tmRequestAuthURLAsync(tmContext ctx, string consumer_key, string consumer_secret);
    [DllImport ("TweetMedia")] public static extern tmAuthState     tmGetRequestAuthURLState(tmContext ctx);

    [DllImport ("TweetMedia")] public static extern tmAuthState     tmEnterPin(tmContext ctx, string pin);
    [DllImport ("TweetMedia")] public static extern void            tmEnterPinAsync(tmContext ctx, string pin);
    [DllImport ("TweetMedia")] public static extern tmAuthState     tmGetEnterPinState(tmContext ctx);

    [DllImport ("TweetMedia")] public static extern bool            tmAddMedia(tmContext ctx, IntPtr data, int data_size, tmEMediaType mtype);
    [DllImport ("TweetMedia")] public static extern bool            tmAddMediaFile(tmContext ctx, string path);
    [DllImport ("TweetMedia")] public static extern void            tmClearMedia(tmContext ctx);

    [DllImport ("TweetMedia")] public static extern int             tmTweet(tmContext ctx, string message);
    [DllImport ("TweetMedia")] public static extern int             tmTweetAsync(tmContext ctx, string message);
    [DllImport ("TweetMedia")] public static extern tmTweetState    tmGetTweetState(tmContext ctx, int thandle);
    [DllImport ("TweetMedia")] public static extern void            tmReleaseTweetCache(tmContext ctx, int thandle);
}
