using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Ist
{

[AddComponentMenu("BatchRenderer/ProceduralGBuffer")]
public class ProceduralGBuffer : MonoBehaviour
{

    public void AddInstanceT(Vector3 t)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
        }
    }
    public void AddInstancesT(Vector3[] t, int start = 0, int length = 0)
    {
        if (length == 0) length = t.Length;
        int reserved_index;
        int reserved_num;
        ReserveInstance(length, out reserved_index, out reserved_num);
        System.Array.Copy(t, start, m_instance_data.translation, reserved_index, reserved_num);
    }

    public void AddInstanceTR(Vector3 t, Quaternion r)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
        }
    }
    public void AddInstancesTR(Vector3[] t, Quaternion[] r, int start = 0, int length = 0)
    {
        if (length == 0) length = t.Length;
        int reserved_index;
        int reserved_num;
        ReserveInstance(length, out reserved_index, out reserved_num);
        System.Array.Copy(t, start, m_instance_data.translation, reserved_index, reserved_num);
        System.Array.Copy(r, start, m_instance_data.rotation, reserved_index, reserved_num);
    }

    public void AddInstanceTRS(Vector3 t, Quaternion r, Vector3 s)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
            m_instance_data.scale[i] = s;
        }
    }
    public void AddInstancesTRS(Vector3[] t, Quaternion[] r, Vector3[] s, int start = 0, int length = 0)
    {
        if (length == 0) length = t.Length;
        int reserved_index;
        int reserved_num;
        ReserveInstance(length, out reserved_index, out reserved_num);
        System.Array.Copy(t, start, m_instance_data.translation, reserved_index, reserved_num);
        System.Array.Copy(r, start, m_instance_data.rotation, reserved_index, reserved_num);
        System.Array.Copy(s, start, m_instance_data.scale, reserved_index, reserved_num);
    }

    public void AddInstanceTRSC(Vector3 t, Quaternion r, Vector3 s, Color c)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
            m_instance_data.scale[i] = s;
            m_instance_data.color[i] = c;
        }
    }

    public void AddInstanceTRSCE(Vector3 t, Quaternion r, Vector3 s, Color c, Color e)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
            m_instance_data.scale[i] = s;
            m_instance_data.color[i] = c;
            m_instance_data.emission[i] = e;
        }
    }

    public void AddInstanceTRC(Vector3 t, Quaternion r, Color c)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
            m_instance_data.color[i] = c;
        }
    }

    public void AddInstanceTRU(Vector3 t, Quaternion r, Vector4 uv)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
            m_instance_data.uv_offset[i] = uv;
        }
    }

    public void AddInstanceTRCU(Vector3 t, Quaternion r, Color c, Vector4 uv)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
            m_instance_data.color[i] = c;
            m_instance_data.uv_offset[i] = uv;
        }
    }

    public void AddInstanceTRSCU(Vector3 t, Quaternion r, Vector3 s, Color c, Vector4 uv)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.rotation[i] = r;
            m_instance_data.scale[i] = s;
            m_instance_data.color[i] = c;
            m_instance_data.uv_offset[i] = uv;
        }
    }


    public InstanceData ReserveInstance(int num, out int reserved_index, out int reserved_num)
    {
        reserved_index = Interlocked.Add(ref m_instance_count, num) - num;
        reserved_num = Mathf.Clamp(m_max_instances - reserved_index, 0, num);
        return m_instance_data;
    }


    [System.Serializable]
    public class InstanceData
    {
        public Vector3[] translation;
        public Quaternion[] rotation;
        public Vector3[] scale;
        public Color[] color;
        public Color[] emission;
        public Vector4[] uv_offset;

        public void Resize(int size)
        {
            translation = new Vector3[size];
            rotation = new Quaternion[size];
            scale = new Vector3[size];
            color = new Color[size];
            emission = new Color[size];
            uv_offset = new Vector4[size];

            Vector3 default_scale = Vector3.one;
            Color default_color = Color.white;
            Vector4 default_uvoffset = new Vector4(1.0f, 1.0f, 0.0f, 0.0f);
            for (int i = 0; i < scale.Length; ++i) { scale[i] = default_scale; }
            for (int i = 0; i < color.Length; ++i) { color[i] = default_color; }
            for (int i = 0; i < uv_offset.Length; ++i) { uv_offset[i] = default_uvoffset; }
        }
    }

    [System.Serializable]
    public class InstanceBuffer
    {
        public ComputeBuffer translation;
        public ComputeBuffer rotation;
        public ComputeBuffer scale;
        public ComputeBuffer color;
        public ComputeBuffer emission;
        public ComputeBuffer uv_offset;

        public void Release()
        {
            if (translation != null) { translation.Release(); translation = null; }
            if (rotation != null) { rotation.Release(); rotation = null; }
            if (scale != null) { scale.Release(); scale = null; }
            if (color != null) { color.Release(); color = null; }
            if (emission != null) { emission.Release(); emission = null; }
            if (uv_offset != null) { uv_offset.Release(); uv_offset = null; }
        }

        public void Allocate(int num_max_instances)
        {
            Release();
            translation = new ComputeBuffer(num_max_instances, 12);
            rotation = new ComputeBuffer(num_max_instances, 16);
            scale = new ComputeBuffer(num_max_instances, 12);
            color = new ComputeBuffer(num_max_instances, 16);
            emission = new ComputeBuffer(num_max_instances, 16);
            uv_offset = new ComputeBuffer(num_max_instances, 16);
        }
    }



    public int m_max_instances = 1024 * 4;
    public Mesh m_mesh;
    public Material m_material;
    public Vector3 m_scale = Vector3.one;
    public Camera m_camera;
    public Vector3 m_bounds_size = Vector3.one;

    public bool m_enable_rotation;
    public bool m_enable_scale;
    public bool m_enable_color;
    public bool m_enable_emission;
    public bool m_enable_uv_offset;

    public int m_instance_count;

    protected InstanceData m_instance_data;
    protected InstanceBuffer m_instance_buffer;
    protected ComputeBuffer m_vertex_buffer;
    protected CommandBuffer m_cb;
    protected int m_vertex_count;

    public int GetMaxInstanceCount() { return m_max_instances; }
    public int GetInstanceCount() { return m_instance_count; }
    public void SetInstanceCount(int v) { m_instance_count = v; }
    public InstanceBuffer GetInstanceBuffer() { return m_instance_buffer; }


    public void ReleaseGPUData()
    {
        if (m_instance_buffer != null) { m_instance_buffer.Release(); }
        if (m_vertex_buffer != null) { m_vertex_buffer.Release(); }
        if (m_cb != null) { m_cb.Release(); }
    }

    public void ResetGPUData()
    {
        ReleaseGPUData();

        m_instance_data.Resize(m_max_instances);
        if (m_instance_buffer != null)
        {
            m_instance_buffer.Allocate(m_max_instances);
        }
        BatchRendererUtil.CreateVertexBuffer(m_mesh, ref m_vertex_buffer, ref m_vertex_count);

        {
            Material m = m_material;
            if (m_enable_rotation)
            {
                m.EnableKeyword("ENABLE_INSTANCE_ROTATION");
            }
            if (m_enable_scale)
            {
                m.EnableKeyword("ENABLE_INSTANCE_SCALE");
            }
            if (m_enable_emission)
            {
                m.EnableKeyword("ENABLE_INSTANCE_EMISSION");
            }
            if (m_enable_color)
            {
                m.EnableKeyword("ENABLE_INSTANCE_COLOR");
            }
            if (m_enable_uv_offset)
            {
                m.EnableKeyword("ENABLE_INSTANCE_UVOFFSET");
            }

            if (m_instance_buffer != null)
            {
                m.SetBuffer("g_vertices", m_vertex_buffer);
                m.SetBuffer("g_instance_buffer_t", m_instance_buffer.translation);
                m.SetBuffer("g_instance_buffer_r", m_instance_buffer.rotation);
                m.SetBuffer("g_instance_buffer_s", m_instance_buffer.scale);
                m.SetBuffer("g_instance_buffer_color", m_instance_buffer.color);
                m.SetBuffer("g_instance_buffer_emission", m_instance_buffer.emission);
                m.SetBuffer("g_instance_buffer_uv", m_instance_buffer.uv_offset);
            }
        }
        {
            m_cb = new CommandBuffer();
            m_cb.name = "ProceduralGBuffer";
            m_cb.DrawProcedural(Matrix4x4.identity, m_material, 0, MeshTopology.Triangles, m_vertex_count, m_max_instances);
            m_camera.AddCommandBuffer(CameraEvent.AfterGBuffer, m_cb);
        }

        // set default values
        UpdateGPUResources();
    }

    public void UpdateGPUResources()
    {
        m_instance_buffer.translation.SetData(m_instance_data.translation);
        if (m_enable_rotation)
        {
            m_instance_buffer.rotation.SetData(m_instance_data.rotation);
        }
        if (m_enable_scale)
        {
            m_instance_buffer.scale.SetData(m_instance_data.scale);
        }
        if (m_enable_color)
        {
            m_instance_buffer.color.SetData(m_instance_data.color);
        }
        if (m_enable_emission)
        {
            m_instance_buffer.emission.SetData(m_instance_data.emission);
        }
        if (m_enable_uv_offset)
        {
            m_instance_buffer.uv_offset.SetData(m_instance_data.uv_offset);
        }
        m_material.SetInt("g_num_instances", m_instance_count);
        m_material.SetVector("g_scale", m_scale);
    }

#if UNITY_EDITOR
    void Reset()
    {
        m_mesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Foundation/Meshes/Cube.asset");
        m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/BatchRenderer/Materials/ProceduralGBuffer.mat");
        m_bounds_size = Vector3.one * 2.0f;
    }
#endif

    public void OnEnable()
    {
        if (!SystemInfo.supportsComputeShaders)
        {
            Debug.Log("ProceduralGBuffer: ComputeBuffer is not available.");
        }

        if (m_mesh == null) return;

        m_instance_data = new InstanceData();
        m_instance_buffer = new InstanceBuffer();

        ResetGPUData();
    }

    public void OnDisable()
    {
        ReleaseGPUData();
    }



    public virtual void Flush()
    {
        m_instance_count = Mathf.Min(m_instance_count, m_max_instances);
        UpdateGPUResources();
        m_instance_count = 0;
    }


    public void LateUpdate()
    {
        Flush();
    }

    public void OnDrawGizmos()
    {
        Transform t = GetComponent<Transform>();
        Vector3 s = t.localScale;

        Gizmos.color = Color.yellow;
        Gizmos.DrawWireCube(t.position, new Vector3(m_bounds_size.x * s.x, m_bounds_size.y * s.y, m_bounds_size.z * s.z));
    }
}

}