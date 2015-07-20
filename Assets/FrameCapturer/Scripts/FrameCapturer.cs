using System;
using System.Collections;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using UnityEngine;

public static class FrameCapturer
{
    public struct fcExrConfig
    {
        public int max_active_tasks;
    };

    public struct fcGifConfig
    {
        public int width;
        public int height;
        public int num_colors;
        public int delay_csec; // * centi second! *
        public int keyframe;
        public int max_active_tasks;
        public int max_frame;
        public int max_data_size;
    };

    [DllImport ("AddLibraryPath")] public static extern void    AddLibraryPath();

    [DllImport ("FrameCapturer")] public static extern IntPtr   fcExrCreateContext(ref fcExrConfig conf);
    [DllImport ("FrameCapturer")] public static extern void     fcExrDestroyContext(IntPtr ctx);
    [DllImport ("FrameCapturer")] public static extern bool     fcExrBeginFrame(IntPtr ctx, string path, int width, int height);
    [DllImport ("FrameCapturer")] public static extern bool     fcExrAddLayer(IntPtr ctx, IntPtr tex, RenderTextureFormat f, int ch, string name);
    [DllImport ("FrameCapturer")] public static extern bool     fcExrEndFrame(IntPtr ctx);

    [DllImport ("FrameCapturer")] public static extern IntPtr   fcGifCreateContext(ref fcGifConfig conf);
    [DllImport ("FrameCapturer")] public static extern void     fcGifDestroyContext(IntPtr ctx);
    [DllImport ("FrameCapturer")] public static extern void     fcGifAddFrame(IntPtr ctx, IntPtr tex);
    [DllImport ("FrameCapturer")] public static extern void     fcGifClearFrame(IntPtr ctx);
    [DllImport ("FrameCapturer")] public static extern void     fcGifWriteFile(IntPtr ctx, string path, int begin_frame=0, int end_frame=-1);
    [DllImport ("FrameCapturer")] public static extern void     fcGifWriteMemory(IntPtr ctx, IntPtr out_buf, int begin_frame=0, int end_frame=-1);
    [DllImport ("FrameCapturer")] public static extern int      fcGifGetFrameCount(IntPtr ctx);
    [DllImport ("FrameCapturer")] public static extern void     fcGifGetFrameData(IntPtr ctx, IntPtr tex, int frame);
    [DllImport ("FrameCapturer")] public static extern int      fcGifGetExpectedDataSize(IntPtr ctx, int begin_frame, int end_frame);
    [DllImport ("FrameCapturer")] public static extern void     fcGifEraseFrame(IntPtr ctx, int begin_frame, int end_frame);
}


public static class FrameCapturerUtils
{
    public static Mesh CreateFullscreenQuad()
    {
        Vector3[] vertices = new Vector3[4] {
                new Vector3( 1.0f, 1.0f, 0.0f),
                new Vector3(-1.0f, 1.0f, 0.0f),
                new Vector3(-1.0f,-1.0f, 0.0f),
                new Vector3( 1.0f,-1.0f, 0.0f),
            };
        int[] indices = new int[6] { 0, 1, 2, 2, 3, 0 };

        Mesh r = new Mesh();
        r.vertices = vertices;
        r.triangles = indices;
        return r;
    }
}
