using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;

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


    const int max_vertices = 65000; // Mesh's limitation


    public enum DataConversion
    {
        Float3ToFloat4,
        Float4ToFloat4,
        Float3ToHalf4,
        Float4ToHalf4,
    }

    [DllImport("CopyToTexture")]
    public static extern void CopyToTexture(System.IntPtr texptr, int width, int height, System.IntPtr dataptr, int data_num, DataConversion conv);

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

    public static void CopyToTexture(RenderTexture rt, System.Array data, int data_num, DataConversion conv)
    {
        System.IntPtr dataptr = Marshal.UnsafeAddrOfPinnedArrayElement(data, 0);
        CopyToTexture(rt.GetNativeTexturePtr(), rt.width, rt.height, dataptr, data_num, conv);
    }

    public static void CopyToTextureViaMesh(RenderTexture rt, Mesh mesh, Material mat, Vector3[] data, int data_num)
    {
        Graphics.SetRenderTarget(rt);
        for (int i = 0; i < data_num; i += mesh.vertexCount)
        {
            var dst1 = mesh.vertices;
            System.Array.Copy(data, i, dst1, 0, Mathf.Min(mesh.vertexCount, data_num - i));
            mesh.vertices = dst1;
            mesh.UploadMeshData(false);
            mat.SetInt("g_begin", i);
            mat.SetPass(0);
            Graphics.DrawMeshNow(mesh, Matrix4x4.identity);
        }
        Graphics.SetRenderTarget(null);
    }
    public static void CopyToTextureViaMesh(RenderTexture rt, Mesh mesh, Material mat, Vector4[] data, int data_num)
    {
        Graphics.SetRenderTarget(rt);
        for (int i = 0; i < data_num; i += mesh.vertexCount)
        {
            int n = Mathf.Min(mesh.vertexCount, data_num - i);
            var dst1 = mesh.vertices;
            var dst2 = mesh.uv;
            for (int vi = 0; vi < n; ++vi)
            {
                int ivi = i + vi;
                var e = data[ivi];
                dst1[vi] = new Vector3(e.x, e.y, e.z);
                dst2[vi] = new Vector2(vi, e.w);
            }
            mesh.vertices = dst1;
            mesh.uv = dst2;
            mesh.UploadMeshData(false);
            mat.SetInt("g_begin", i);
            mat.SetPass(0);
            Graphics.DrawMeshNow(mesh, Matrix4x4.identity);
        }
        Graphics.SetRenderTarget(null);
    }
    public static void CopyToTextureViaMesh(RenderTexture rt, Mesh mesh, Material mat, Quaternion[] data, int data_num)
    {
        Graphics.SetRenderTarget(rt);
        for (int i = 0; i < data_num; i += mesh.vertexCount)
        {
            int n = Mathf.Min(mesh.vertexCount, data_num - i);
            var dst1 = mesh.vertices;
            var dst2 = mesh.uv;
            for (int vi = 0; vi < n; ++vi)
            {
                int ivi = i + vi;
                var e = data[ivi];
                dst1[vi] = new Vector3(e.x, e.y, e.z);
                dst2[vi] = new Vector2(vi, e.w);
            }
            mesh.vertices = dst1;
            mesh.uv = dst2;
            mesh.UploadMeshData(false);
            mat.SetInt("g_begin", i);
            mat.SetPass(0);
            Graphics.DrawMeshNow(mesh, Matrix4x4.identity);
        }
        Graphics.SetRenderTarget(null);
    }
    public static void CopyToTextureViaMesh(RenderTexture rt, Mesh mesh, Material mat, Color[] data, int data_num)
    {
        Graphics.SetRenderTarget(rt);
        for (int i = 0; i < data_num; i += mesh.vertexCount)
        {
            int n = Mathf.Min(mesh.vertexCount, data_num - i);
            var dst1 = mesh.vertices;
            var dst2 = mesh.uv;
            for (int vi = 0; vi < n; ++vi)
            {
                int ivi = i + vi;
                var e = data[ivi];
                dst1[vi] = new Vector3(e.r, e.g, e.b);
                dst2[vi] = new Vector2(vi, e.a);
            }
            mesh.vertices = dst1;
            mesh.uv = dst2;
            mesh.UploadMeshData(false);
            mat.SetInt("g_begin", i);
            mat.SetPass(0);
            Graphics.DrawMeshNow(mesh, Matrix4x4.identity);
        }
        Graphics.SetRenderTarget(null);
    }


    public static Mesh CreateExpandedMesh(Mesh mesh, out int instances_par_batch)
    {
        Vector3[] vertices_base = mesh.vertices;
        Vector3[] normals_base = (mesh.normals == null || mesh.normals.Length == 0) ? null : mesh.normals;
        Vector4[] tangents_base = (mesh.tangents == null || mesh.tangents.Length == 0) ? null : mesh.tangents;
        Vector2[] uv_base = (mesh.uv == null || mesh.uv.Length == 0) ? null : mesh.uv;
        Color[] colors_base = (mesh.colors == null || mesh.colors.Length == 0) ? null : mesh.colors;
        int[] indices_base = (mesh.triangles == null || mesh.triangles.Length == 0) ? null : mesh.triangles;
        instances_par_batch = max_vertices / mesh.vertexCount;

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

    public static Mesh CreateDataTransferMesh(int num_vertices)
    {
        int n = Mathf.Min(num_vertices, max_vertices);
        Vector3[] vertices = new Vector3[n];
        Vector2[] uv = new Vector2[n];
        int[] indices = new int[n];
        for (int i = 0; i < n; ++i)
        {
            uv[i].x = i;
            indices[i] = i;
        }

        Mesh ret = new Mesh();
        ret.MarkDynamic();
        ret.vertices = vertices;
        ret.uv = uv;
        ret.SetIndices(indices, MeshTopology.Points, 0);
        return ret;
    }

    // なんか WebGL だと POINT が表示されないので LINE 代用版
    public static Mesh CreateDataTransferMesh_Line(int num_vertices)
    {
        int n = Mathf.Min(num_vertices, max_vertices);
        Vector3[] vertices = new Vector3[n];
        Vector2[] uv = new Vector2[n];
        int[] indices = new int[n*2];
        for (int i = 0; i < n; ++i)
        {
            uv[i].x = i;
            uv[i].y = 1.0f;
            indices[i * 2 + 0] = i;
            indices[i * 2 + 1] = i + 128 >= n ? i : i + 128;
        }

        Mesh ret = new Mesh();
        ret.MarkDynamic();
        ret.vertices = vertices;
        ret.uv = uv;
        //ret.SetIndices(indices, MeshTopology.Points, 0);
        ret.SetIndices(indices, MeshTopology.Lines, 0);
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
        return v/d + (v%d==0 ? 0 : 1);
    }
}

