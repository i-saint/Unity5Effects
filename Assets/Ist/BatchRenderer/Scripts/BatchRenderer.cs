using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;


namespace Ist
{

public class BatchRenderer : BatchRendererBase
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

    public void AddInstanceTS(Vector3 t, Vector3 s)
    {
        int i = Interlocked.Increment(ref m_instance_count) - 1;
        if (i < m_max_instances)
        {
            m_instance_data.translation[i] = t;
            m_instance_data.scale[i] = s;
        }
    }
    public void AddInstancesTS(Vector3[] t, Vector3[] s, int start = 0, int length = 0)
    {
        if (length == 0) length = t.Length;
        int reserved_index;
        int reserved_num;
        ReserveInstance(length, out reserved_index, out reserved_num);
        System.Array.Copy(t, start, m_instance_data.translation, reserved_index, reserved_num);
        System.Array.Copy(s, start, m_instance_data.scale, reserved_index, reserved_num);
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


    public enum DataTransferMode
    {
        Buffer,
        TextureWithPlugin,
        Texture,
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
            if (translation != null){ translation.Release(); translation = null; }
            if (rotation != null)   { rotation.Release(); rotation = null; }
            if (scale != null)      { scale.Release(); scale = null; }
            if (color != null)      { color.Release(); color = null; }
            if (emission != null)   { emission.Release(); emission = null; }
            if (uv_offset != null)  { uv_offset.Release(); uv_offset = null; }
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

    [System.Serializable]
    public class InstanceTexture
    {

        public Texture2D translation;
        public Texture2D rotation;
        public Texture2D scale;
        public Texture2D color;
        public Texture2D emission;
        public Texture2D uv_offset;

        public void Release()
        {
            if (translation != null) { translation = null; }
            if (rotation != null) { rotation = null; }
            if (scale != null) { scale = null; }
            if (color != null) { color = null; }
            if (emission != null) { emission = null; }
            if (uv_offset != null) { uv_offset = null; }
        }

        Texture2D CreateDataTexture(int num_max_instances)
        {
            int width = BatchRendererUtil.data_texture_width;
            int height = BatchRendererUtil.ceildiv(num_max_instances, width);
            Texture2D r = null;

            if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBFloat))
            {
                r = new Texture2D(width, height, TextureFormat.RGBAFloat, false);
            }
            else if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf))
            {
                Debug.Log("BatchRenderer: float texture is not available. use half texture instead");
                r = new Texture2D(width, height, TextureFormat.RGBAHalf, false);
            }
            else
            {
                Debug.Log("BatchRenderer: both float and half texture are not available. give up.");
                return null;
            }


            r.filterMode = FilterMode.Point;
            return r;
        }

        public void Allocate(int num_max_instances)
        {
            Release();
            translation = CreateDataTexture(num_max_instances);
            rotation = CreateDataTexture(num_max_instances);
            scale = CreateDataTexture(num_max_instances);
            color = CreateDataTexture(num_max_instances);
            emission = CreateDataTexture(num_max_instances);
            uv_offset = CreateDataTexture(num_max_instances);
        }
    }


    public bool m_enable_rotation;
    public bool m_enable_scale;
    public bool m_enable_color;
    public bool m_enable_emission;
    public bool m_enable_uv_offset;

    public DataTransferMode m_data_transfer_mode;
    public bool m_dbg_show_data_texture = false;

    protected InstanceData m_instance_data;
    protected InstanceBuffer m_instance_buffer;
    [SerializeField] protected InstanceTexture m_instance_texture;
    protected Vector4 m_instance_texel_size;
    protected byte[] m_data_transfer_buffer;


    public InstanceBuffer GetInstanceBuffer() { return m_instance_buffer; }
    public InstanceTexture GetInstanceTexture() { return m_instance_texture; }


    public void ReleaseGPUData()
    {
        if (m_instance_buffer != null) { m_instance_buffer.Release(); }
        if (m_instance_texture != null) { m_instance_texture.Release(); }
        ClearMaterials();
    }

    public void ResetGPUData()
    {
        ReleaseGPUData();

        m_instance_data.Resize(m_max_instances);
        if (m_instance_buffer != null)
        {
            m_instance_buffer.Allocate(m_max_instances);
        }
        if (m_instance_texture != null)
        {
            m_instance_texture.Allocate(m_max_instances);
            m_instance_texel_size = new Vector4(
                1.0f / m_instance_texture.translation.width,
                1.0f / m_instance_texture.translation.height,
                m_instance_texture.translation.width,
                m_instance_texture.translation.height);
        }


        // set default values
        UpdateGPUResources();
    }

    public override Material CloneMaterial(Material src, int nth)
    {
        Material m = new Material(src);
        if (m_data_transfer_mode == DataTransferMode.Buffer)
        {
            m.EnableKeyword("ENABLE_INSTANCE_BUFFER");
        }
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

        m.SetInt("g_batch_begin", nth * m_instances_par_batch);
        m.SetVector("g_texel_size", m_instance_texel_size);

        if (m_instance_buffer != null)
        {
            m.SetBuffer("g_instance_buffer_t", m_instance_buffer.translation);
            m.SetBuffer("g_instance_buffer_r", m_instance_buffer.rotation);
            m.SetBuffer("g_instance_buffer_s", m_instance_buffer.scale);
            m.SetBuffer("g_instance_buffer_color", m_instance_buffer.color);
            m.SetBuffer("g_instance_buffer_emission", m_instance_buffer.emission);
            m.SetBuffer("g_instance_buffer_uv", m_instance_buffer.uv_offset);
        }
        if (m_instance_texture != null)
        {
            m.SetTexture("g_instance_texture_t", m_instance_texture.translation);
            m.SetTexture("g_instance_texture_r", m_instance_texture.rotation);
            m.SetTexture("g_instance_texture_s", m_instance_texture.scale);
            m.SetTexture("g_instance_texture_color", m_instance_texture.color);
            m.SetTexture("g_instance_texture_emission", m_instance_texture.emission);
            m.SetTexture("g_instance_texture_uv", m_instance_texture.uv_offset);
        }

        // fix rendering order for transparent objects
        if (m.renderQueue >= 3000)
        {
            m.renderQueue = m.renderQueue + (nth + 1);
        }
        return m;
    }

    public override void UpdateGPUResources()
    {
        switch(m_data_transfer_mode)
        {
            case DataTransferMode.Buffer:
                UploadInstanceData_Buffer();
                break;
            case DataTransferMode.Texture:
                UploadInstanceData_Texture();
                break;
            case DataTransferMode.TextureWithPlugin:
                UploadInstanceData_TextureWithPlugin();
                break;
        }
        ForEachEveryMaterials((v) =>
        {
            v.SetInt("g_num_instances", m_instance_count);
            v.SetVector("g_scale", m_scale);
        });
    }

    public void UploadInstanceData_Buffer()
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
    }

    public void UploadInstanceData_Texture()
    {
        if (m_data_transfer_buffer == null)
        {
            var t = m_instance_texture.translation;
            if (t.format == TextureFormat.RGBAFloat)
            {
                m_data_transfer_buffer = new byte[t.width * t.height * 16];
            }
            else if (t.format == TextureFormat.RGBAHalf)
            {
                m_data_transfer_buffer = new byte[t.width * t.height * 8];
            }
            else
            {
                Debug.Log("should not happen");
            }
        }

        BatchRendererUtil.CopyToTextureCS(m_instance_texture.translation, m_instance_data.translation, m_instance_count, m_data_transfer_buffer);
        if (m_enable_rotation)
        {
            BatchRendererUtil.CopyToTextureCS(m_instance_texture.rotation, m_instance_data.rotation, m_instance_count, m_data_transfer_buffer);
        }
        if (m_enable_scale)
        {
            BatchRendererUtil.CopyToTextureCS(m_instance_texture.scale, m_instance_data.scale, m_instance_count, m_data_transfer_buffer);
        }
        if (m_enable_color)
        {
            BatchRendererUtil.CopyToTextureCS(m_instance_texture.color, m_instance_data.color, m_instance_count, m_data_transfer_buffer);
        }
        if (m_enable_emission)
        {
            BatchRendererUtil.CopyToTextureCS(m_instance_texture.emission, m_instance_data.emission, m_instance_count, m_data_transfer_buffer);
        }
        if (m_enable_uv_offset)
        {
            BatchRendererUtil.CopyToTextureCS(m_instance_texture.uv_offset, m_instance_data.uv_offset, m_instance_count, m_data_transfer_buffer);
        }
    }

    public void UploadInstanceData_TextureWithPlugin()
    {
        BatchRendererUtil.DataConversion cv34 = BatchRendererUtil.DataConversion.Float3ToFloat4;
        BatchRendererUtil.DataConversion cv44 = BatchRendererUtil.DataConversion.Float4ToFloat4;
        if (m_instance_texture.translation.format == TextureFormat.RGBAHalf)
        {
            cv34 = BatchRendererUtil.DataConversion.Float3ToHalf4;
            cv44 = BatchRendererUtil.DataConversion.Float4ToHalf4;
        }

        BatchRendererUtil.CopyToTexturePlugin(m_instance_texture.translation, m_instance_data.translation, m_instance_count, cv34);
        if (m_enable_rotation)
        {
            BatchRendererUtil.CopyToTexturePlugin(m_instance_texture.rotation, m_instance_data.rotation, m_instance_count, cv44);
        }
        if (m_enable_scale)
        {
            BatchRendererUtil.CopyToTexturePlugin(m_instance_texture.scale, m_instance_data.scale, m_instance_count, cv34);
        }
        if (m_enable_color)
        {
            BatchRendererUtil.CopyToTexturePlugin(m_instance_texture.color, m_instance_data.color, m_instance_count, cv44);
        }
        if (m_enable_emission)
        {
            BatchRendererUtil.CopyToTexturePlugin(m_instance_texture.emission, m_instance_data.emission, m_instance_count, cv44);
        }
        if (m_enable_uv_offset)
        {
            BatchRendererUtil.CopyToTexturePlugin(m_instance_texture.uv_offset, m_instance_data.uv_offset, m_instance_count, cv44);
        }
    }

#if UNITY_EDITOR
    void Reset()
    {
        m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/BatchRenderer/Materials/BatchLambert.mat");
        m_mesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/BatchRenderer/Meshes/cube.asset");
    }
#endif

    public override void OnEnable()
    {
        base.OnEnable();
        if (m_mesh == null) return;

        if (m_data_transfer_mode == DataTransferMode.Buffer && !SystemInfo.supportsComputeShaders)
        {
            Debug.Log("BatchRenderer: ComputeBuffer is not available. fallback to Texture data transfer mode.");
            m_data_transfer_mode = DataTransferMode.Texture;
        }
        if (m_data_transfer_mode == DataTransferMode.TextureWithPlugin && !BatchRendererUtil.IsCopyToTextureAvailable())
        {
            Debug.Log("BatchRenderer: CopyToTexture plugin is not available. fallback to Texture data transfer mode.");
            m_data_transfer_mode = DataTransferMode.Texture;
        }

        m_instance_data = new InstanceData();
        if (m_data_transfer_mode == DataTransferMode.Buffer)
        {
            m_instance_buffer = new InstanceBuffer();
        }
        else
        {
            m_instance_texture = new InstanceTexture();
        }

        ResetGPUData();
    }

    public override void OnDisable()
    {
        base.OnDisable();
        ReleaseGPUData();
    }

    void OnGUI()
    {
        if (m_instance_texture != null && m_dbg_show_data_texture)
        {
            GUI.DrawTexture(new Rect(5, 5, 128, 128), m_instance_texture.translation);
        }
    }
}

}