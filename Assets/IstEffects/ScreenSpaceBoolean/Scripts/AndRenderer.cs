using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("IstEffects/ScreenSpaceBoolean/AndRenderer")]
[ExecuteInEditMode]
public class AndRenderer : MonoBehaviour
{
    #region fields
    public Mesh m_quad;
    public Shader m_shader;

    Material m_material;
    CommandBuffer m_commands;
    List<Camera> m_cameras = new List<Camera>();
    #endregion


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
        m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/IstEffects/ScreenSpaceBoolean/Shaders/CompositeAnd.shader");
    }
#endif // UNITY_EDITOR

    void OnDestroy()
    {
        Object.DestroyImmediate(m_material);
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
    
    void OnPreRender()
    {
        if (!gameObject.activeInHierarchy && !enabled) { return; }

        var cam = GetComponent<Camera>();

        UpdateCommandBuffer();

        if (!m_cameras.Contains(cam))
        {
            cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
            m_cameras.Add(cam);
        }
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
        if (m_commands == null)
        {
            m_commands = new CommandBuffer();
            m_commands.name = "AndRenderer";
            m_material = new Material(m_shader);
        }

        m_commands.Clear();
        var ganded = IAndReceiver.GetGroups();
        var gander = IAndOperator.GetGroups();
        foreach (var v in ganded)
        {
            if (gander.ContainsKey(v.Key))
            {
                IssueDrawcalls(v.Value, gander[v.Key]);
            }
        }
    }

    void IssueDrawcalls(List<IAndReceiver> receivers, List<IAndOperator> operators)
    {
        int num_receivers = receivers.Count;
        int num_operators = operators.Count;

        int id_backdepth = Shader.PropertyToID("BackDepth");
        int id_frontdepth = Shader.PropertyToID("TmpDepth"); // reuse SubtractionRenderer's buffer
        int id_backdepth2 = Shader.PropertyToID("BackDepth2");
        int id_frontdepth2 = Shader.PropertyToID("TmpDepth2");

        // back depth - receivers
        m_commands.GetTemporaryRT(id_backdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
        m_commands.SetRenderTarget(id_backdepth);
        m_commands.ClearRenderTarget(true, true, Color.black, 0.0f);
        for (int i = 0; i < num_receivers; ++i)
        {
            if (receivers[i] != null)
            {
                receivers[i].IssueDrawCall_BackDepth(this, m_commands);
            }
        }
        m_commands.SetGlobalTexture("_BackDepth", id_backdepth);

        // back depth - operators
        m_commands.GetTemporaryRT(id_backdepth2, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
        m_commands.SetRenderTarget(id_backdepth2);
        m_commands.ClearRenderTarget(true, true, Color.black, 0.0f);
        for (int i = 0; i < num_operators; ++i)
        {
            if (operators[i] != null)
            {
                operators[i].IssueDrawCall_BackDepth(this, m_commands);
            }
        }
        m_commands.SetGlobalTexture("_BackDepth2", id_backdepth2);


        // front depth - receivers
        m_commands.GetTemporaryRT(id_frontdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
        m_commands.SetRenderTarget(id_frontdepth);
        m_commands.ClearRenderTarget(true, true, Color.black, 1.0f);
        for (int i = 0; i < num_receivers; ++i)
        {
            if (receivers[i] != null)
            {
                receivers[i].IssueDrawCall_FrontDepth(this, m_commands);
            }
        }
        m_commands.SetGlobalTexture("_FrontDepth", id_frontdepth);

        // front depth - operators
        m_commands.GetTemporaryRT(id_frontdepth2, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
        m_commands.SetRenderTarget(id_frontdepth2);
        m_commands.ClearRenderTarget(true, true, Color.black, 1.0f);
        for (int i = 0; i < num_operators; ++i)
        {
            if (operators[i] != null)
            {
                operators[i].IssueDrawCall_FrontDepth(this, m_commands);
            }
        }
        m_commands.SetGlobalTexture("_FrontDepth2", id_frontdepth2);


        // output depth
        m_commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        m_commands.DrawMesh(m_quad, Matrix4x4.identity, m_material);
    }
}
