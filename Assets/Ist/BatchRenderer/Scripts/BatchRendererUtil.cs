using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;



namespace Ist
{

public static class BatchRendererUtil
{
    public static Vector4 ComputeUVOffset(Texture texture, Rect rect)
    {
        float tw = texture.width;
        float th = texture.height;
        return new Vector4(
            rect.width / tw,
            rect.height / th,
            rect.xMin / tw,
            (1.0f - rect.yMax) / th);
    }

    public static Vector4 ComputeUVOffset(int texture_width, int texture_height, Rect rect)
    {
        float tw = texture_width;
        float th = texture_height;
        return new Vector4(
            rect.width / tw,
            rect.height / th,
            rect.xMin / tw,
            (1.0f - rect.yMax) / th);
    }


    public const int max_vertices = 65000; // Mesh's limitation
    public const int data_texture_width = 128;
    public const int max_data_transfer_size = 64768;


    public enum DataConversion
    {
        Float3ToFloat4,
        Float4ToFloat4,
        Float3ToHalf4,
        Float4ToHalf4,
    }

    [DllImport("CopyToTexture")]
    public static extern void CopyToTexture(System.IntPtr texptr, int width, int height, System.IntPtr dataptr, int num_data, DataConversion conv);

    public static bool IsCopyToTextureAvailable()
    {
        try
        {
            CopyToTexture(System.IntPtr.Zero, 0, 0, System.IntPtr.Zero, 0, DataConversion.Float3ToFloat4);
        }
        catch(System.Exception)
        {
            return false;
        }
        return true;
    }


    public static void CopyToTexturePlugin(Texture2D rt, System.Array data, int num_data, DataConversion conv)
    {
        System.IntPtr dataptr = Marshal.UnsafeAddrOfPinnedArrayElement(data, 0);
        CopyToTexture(rt.GetNativeTexturePtr(), rt.width, rt.height, dataptr, num_data, conv);
    }



    public static void CopyToTextureCS(Texture2D tex, Vector3[] data, int num_data, byte[] buffer)
    {
        if (tex.format == TextureFormat.RGBAFloat)
        {
            float[] buf = ArrayCaster<byte, float>.cast(buffer);
            for(int i=0; i < num_data; ++i)
            {
                buf[i * 4 + 0] = data[i].x;
                buf[i * 4 + 1] = data[i].y;
                buf[i * 4 + 2] = data[i].z;
                buf[i * 4 + 3] = 1.0f; // for debug
            }
        }
        else if (tex.format == TextureFormat.RGBAHalf)
        {
            ushort[] buf = ArrayCaster<byte, ushort>.cast(buffer);
            ushort one = HalfConverter.ToHalf(1.0f);
            for (int i = 0; i < num_data; ++i)
            {
                buf[i * 4 + 0] = HalfConverter.ToHalf(data[i].x);
                buf[i * 4 + 1] = HalfConverter.ToHalf(data[i].y);
                buf[i * 4 + 2] = HalfConverter.ToHalf(data[i].z);
                buf[i * 4 + 3] = one; // for debug
            }
        }
        else
        {
            Debug.Log("unsupported format");
            return;
        }
        tex.LoadRawTextureData(buffer);
        tex.Apply();
    }
    public static void CopyToTextureCS(Texture2D tex, Vector4[] data, int num_data, byte[] buffer)
    {
        if (tex.format == TextureFormat.RGBAFloat)
        {
            float[] buf = ArrayCaster<byte, float>.cast(buffer);
            for (int i = 0; i < num_data; ++i)
            {
                buf[i * 4 + 0] = data[i].x;
                buf[i * 4 + 1] = data[i].y;
                buf[i * 4 + 2] = data[i].z;
                buf[i * 4 + 3] = data[i].w;
            }
        }
        else if (tex.format == TextureFormat.RGBAHalf)
        {
            ushort[] buf = ArrayCaster<byte, ushort>.cast(buffer);
            for (int i = 0; i < num_data; ++i)
            {
                buf[i * 4 + 0] = HalfConverter.ToHalf(data[i].x);
                buf[i * 4 + 1] = HalfConverter.ToHalf(data[i].y);
                buf[i * 4 + 2] = HalfConverter.ToHalf(data[i].z);
                buf[i * 4 + 3] = HalfConverter.ToHalf(data[i].w);
            }
        }
        else
        {
            Debug.Log("unsupported format");
            return;
        }
        tex.LoadRawTextureData(buffer);
        tex.Apply();
    }
    public static void CopyToTextureCS(Texture2D tex, Quaternion[] data, int num_data, byte[] buffer)
    {
        CopyToTextureCS(tex, ArrayCaster<Quaternion, Vector4>.cast(data), num_data, buffer);
    }
    public static void CopyToTextureCS(Texture2D tex, Color[] data, int num_data, byte[] buffer)
    {
        CopyToTextureCS(tex, ArrayCaster<Color, Vector4>.cast(data), num_data, buffer);
    }
    


    public static Mesh CreateExpandedMesh(Mesh mesh, int required_instances, out int instances_par_batch)
    {
        Vector3[] vertices_base = mesh.vertices;
        Vector3[] normals_base = (mesh.normals == null || mesh.normals.Length == 0) ? null : mesh.normals;
        Vector4[] tangents_base = (mesh.tangents == null || mesh.tangents.Length == 0) ? null : mesh.tangents;
        Vector2[] uv_base = (mesh.uv == null || mesh.uv.Length == 0) ? null : mesh.uv;
        Color[] colors_base = (mesh.colors == null || mesh.colors.Length == 0) ? null : mesh.colors;
        int[] indices_base = (mesh.triangles == null || mesh.triangles.Length == 0) ? null : mesh.triangles;
        instances_par_batch = Mathf.Min(max_vertices / mesh.vertexCount, required_instances);

        Vector3[] vertices = new Vector3[vertices_base.Length * instances_par_batch];
        Vector2[] idata = new Vector2[vertices_base.Length * instances_par_batch];
        Vector3[] normals = normals_base == null ? null : new Vector3[normals_base.Length * instances_par_batch];
        Vector4[] tangents = tangents_base == null ? null : new Vector4[tangents_base.Length * instances_par_batch];
        Vector2[] uv = uv_base == null ? null : new Vector2[uv_base.Length * instances_par_batch];
        Color[] colors = colors_base == null ? null : new Color[colors_base.Length * instances_par_batch];
        int[] indices = indices_base == null ? null : new int[indices_base.Length * instances_par_batch];

        for (int ii = 0; ii < instances_par_batch; ++ii)
        {
            for (int vi = 0; vi < vertices_base.Length; ++vi)
            {
                int i = ii * vertices_base.Length + vi;
                vertices[i] = vertices_base[vi];
                idata[i] = new Vector2((float)ii, (float)vi);
            }
            if (normals != null)
            {
                for (int vi = 0; vi < normals_base.Length; ++vi)
                {
                    int i = ii * normals_base.Length + vi;
                    normals[i] = normals_base[vi];
                }
            }
            if (tangents != null)
            {
                for (int vi = 0; vi < tangents_base.Length; ++vi)
                {
                    int i = ii * tangents_base.Length + vi;
                    tangents[i] = tangents_base[vi];
                }
            }
            if (uv != null)
            {
                for (int vi = 0; vi < uv_base.Length; ++vi)
                {
                    int i = ii * uv_base.Length + vi;
                    uv[i] = uv_base[vi];
                }
            }
            if (colors != null)
            {
                for (int vi = 0; vi < colors_base.Length; ++vi)
                {
                    int i = ii * colors_base.Length + vi;
                    colors[i] = colors_base[vi];
                }
            }
            if (indices != null)
            {
                for (int vi = 0; vi < indices_base.Length; ++vi)
                {
                    int i = ii * indices_base.Length + vi;
                    indices[i] = ii * vertices_base.Length + indices_base[vi];
                }
            }

        }
        Mesh ret = new Mesh();
        ret.vertices = vertices;
        ret.normals = normals;
        ret.tangents = tangents;
        ret.uv = uv;
        ret.colors = colors;
        ret.uv2 = idata;
        ret.triangles = indices;
        return ret;
    }


    public static Mesh CreateIndexOnlyMesh(int num_vertices, int[] indices_base, out int instances_par_batch)
    {
        int num_indices = indices_base.Length;
        instances_par_batch = max_vertices / num_vertices;

        Vector3[] vertices = new Vector3[num_vertices * instances_par_batch];
        int[] indices = new int[num_indices * instances_par_batch];
        for (int ii = 0; ii < instances_par_batch; ++ii)
        {
            for (int vi = 0; vi < num_vertices; ++vi)
            {
                int i = ii * num_vertices + vi;
                vertices[i].x = vi;
                vertices[i].y = ii;
            }
            for (int di = 0; di < num_indices; ++di)
            {
                int i = ii * num_indices + di;
                indices[i] = ii * num_vertices + indices_base[di];
            }
        }

        Mesh ret = new Mesh();
        ret.vertices = vertices;
        ret.triangles = indices;
        return ret;
    }
    


    public static void Swap<T>(ref T lhs, ref T rhs)
    {
        T temp;
        temp = lhs;
        lhs = rhs;
        rhs = temp;
    }

    public struct VertexT
    {
        public const int size = 48;

        public Vector3 vertex;
        public Vector3 normal;
        public Vector4 tangent;
        public Vector2 texcoord;
    }

    public static void CreateVertexBuffer(Mesh mesh, ref ComputeBuffer ret, ref int num_vertices)
    {
        int[] indices = mesh.GetIndices(0);
        Vector3[] vertices = mesh.vertices;
        Vector3[] normals = mesh.normals;
        Vector4[] tangents = mesh.tangents;
        Vector2[] uv = mesh.uv;

        VertexT[] v = new VertexT[indices.Length];
        if (vertices != null) { for (int i = 0; i < indices.Length; ++i) { v[i].vertex = vertices[indices[i]]; } }
        if (normals != null) { for (int i = 0; i < indices.Length; ++i) { v[i].normal = normals[indices[i]]; } }
        if (tangents != null) { for (int i = 0; i < indices.Length; ++i) { v[i].tangent = tangents[indices[i]]; } }
        if (uv != null) { for (int i = 0; i < indices.Length; ++i) { v[i].texcoord = uv[indices[i]]; } }

        ret = new ComputeBuffer(indices.Length, VertexT.size);
        ret.SetData(v);
        num_vertices = v.Length;
    }

    public static int ceildiv(int v, int d)
    {
        return v / d + (v % d == 0 ? 0 : 1);
    }
}

}