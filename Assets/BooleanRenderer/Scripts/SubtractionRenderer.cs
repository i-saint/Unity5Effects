using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/SubtractionRenderer")]
[ExecuteInEditMode]
public class SubtractionRenderer : MonoBehaviour
{
    static private List<SubtractionRenderer> s_instances;
    static public List<SubtractionRenderer> instances
    {
        get
        {
            if (s_instances == null) { s_instances = new List<SubtractionRenderer>(); }
            return s_instances;
        }
    }


    public bool m_enable_masking = true;
    public bool m_enable_piercing = true;

    public Mesh m_quad;
    public Shader m_sh_composite;

    List<ISubtracted> m_subtracted = new List<ISubtracted>();
    List<ISubtractor> m_subtractor = new List<ISubtractor>();
    Material m_mat_composite;
    CommandBuffer m_commands;
    RenderTargetIdentifier[] m_gbuffer_rt;
    List<Camera> m_cameras = new List<Camera>();
    bool m_dirty = true;


    public void AddSubtracted(ISubtracted v) { m_subtracted.Add(v); }
    public void AddSubtractor(ISubtractor v) { m_subtractor.Add(v); }
    public void RemoveSubtracted(ISubtracted v) { m_subtracted.Remove(v); }
    public void RemoveSubtractor(ISubtractor v) { m_subtractor.Remove(v); }


    public static Mesh GenerateQuad()
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

#if UNITY_EDITOR
    void Reset()
    {
        m_quad = GenerateQuad();
        m_sh_composite = AssetDatabase.LoadAssetAtPath<Shader>("Assets/BooleanRenderer/Shaders/Composite.shader");
    }
#endif // UNITY_EDITOR

    void Awake()
    {
        instances.Add(this);
    }

    void OnDestroy()
    {
        instances.Remove(this);
    }

    void OnDisable()
    {
        if (m_commands != null)
        {
            int c = m_cameras.Count;
            for (int i = 0; i < c; ++i )
            {
                if (m_cameras[i] != null)
                {
                    m_cameras[i].RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
                }
            }
            m_cameras.Clear();
        }
    }

    void LateUpdate()
    {
        m_dirty = true;
    }

    void OnWillRenderObject()
    {
        if (!gameObject.activeInHierarchy && !enabled) { return; }

        var cam = Camera.current;
        if (!cam) { return; }

        UpdateCommandBuffer();

        if (!m_cameras.Contains(cam))
        {
            cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
            m_cameras.Add(cam);
        }
    }

    void UpdateCommandBuffer()
    {
        if (!m_dirty) { return; }
        m_dirty = false;

        int num_subtractor = m_subtractor.Count;
        int num_subtracted = m_subtracted.Count;
        int id_backdepth = Shader.PropertyToID("BackDepth");
        int id_tmpdepth = Shader.PropertyToID("TmpDepth");

        if (m_commands == null)
        {
            m_commands = new CommandBuffer();
            m_commands.name = "SubtractionRenderer";
            m_gbuffer_rt = new RenderTargetIdentifier[]
            {
                BuiltinRenderTextureType.GBuffer0,
                BuiltinRenderTextureType.GBuffer1,
                BuiltinRenderTextureType.GBuffer2,
                BuiltinRenderTextureType.CameraTarget,
            };
            m_mat_composite = new Material(m_sh_composite);
        }

        m_commands.Clear();
        if (m_enable_piercing)
        {
            m_commands.GetTemporaryRT(id_backdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
            m_commands.SetRenderTarget(id_backdepth);
            m_commands.ClearRenderTarget(true, true, Color.black, 0.0f);
            for (int i = 0; i < num_subtracted; ++i)
            {
                if (m_subtracted[i] != null)
                {
                    m_subtracted[i].IssueDrawCall_BackDepth(this, m_commands);
                }
            }
            m_commands.SetGlobalTexture("_BackDepth", id_backdepth);
        }

        m_commands.GetTemporaryRT(id_tmpdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
        m_commands.SetRenderTarget(id_tmpdepth);
        m_commands.ClearRenderTarget(true, true, Color.black, 1.0f);
        for (int i = 0; i < num_subtracted; ++i)
        {
            if (m_subtracted[i] != null)
            {
                m_subtracted[i].IssueDrawCall_DepthMask(this, m_commands);
            }
        }
        for (int i = 0; i < num_subtractor; ++i)
        {
            if (m_subtractor[i] != null)
            {
                m_subtractor[i].IssueDrawCall_DepthMask(this, m_commands);
            }
        }

        m_commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        m_commands.SetGlobalTexture("_TmpDepth", id_tmpdepth);
        m_commands.DrawMesh(m_quad, Matrix4x4.identity, m_mat_composite);
    }
}
