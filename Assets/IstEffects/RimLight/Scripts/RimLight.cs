using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(Camera))]
[RequireComponent(typeof(GBufferUtils))]
[ExecuteInEditMode]
public class RimLight : MonoBehaviour
{
    public Vector4 m_color = new Vector4(0.75f, 0.75f, 1.25f, 0.0f);
    public float m_intensity = 0.5f;
    public float m_factor = 1.5f;
    public float m_threshold = 0.5f;
    public bool m_edge_highlighting = true;
    public float m_edge_intensity = 0.4f;
    public float m_edge_threshold = 0.8f;
    public bool m_smoothness_attenuation = true;
    public Shader m_shader;
    public Mesh m_quad;
    Material m_material;
    CommandBuffer m_commands;

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
        r.name = "Quad";
        r.vertices = vertices;
        r.triangles = indices;
        return r;
    }


#if UNITY_EDITOR
    void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/IstEffects/RimLight/Shaders/RimLight.shader");
        m_quad = GenerateQuad();
        GetComponent<GBufferUtils>().m_enable_inv_matrices = true;
    }
#endif // UNITY_EDITOR

    void OnDestroy()
    {
        if (m_material != null)
        {
            Object.DestroyImmediate(m_material);
        }
    }

    void OnDisable()
    {
        if (m_commands != null)
        {
            var cam = GetComponent<Camera>();
            cam.RemoveCommandBuffer(CameraEvent.AfterLighting, m_commands);
            m_commands.Release();
            m_commands = null;
        }
    }

    void Update()
    {
    }

    void OnPreRender()
    {
        if (!gameObject.activeInHierarchy && !enabled) { return; }

        var cam = GetComponent<Camera>();
        if (m_commands == null)
        {
            m_material = new Material(m_shader);
            m_commands = new CommandBuffer();
            m_commands.name = "Rim Light";

            cam.AddCommandBuffer(CameraEvent.AfterLighting, m_commands);
            m_commands.DrawMesh(m_quad, Matrix4x4.identity, m_material, 0, 0);
        }

        if (cam.hdr)
        {
            m_material.EnableKeyword("UNITY_HDR_ON");
            m_material.SetInt("_SrcBlend", (int)BlendMode.One);
            m_material.SetInt("_DstBlend", (int)BlendMode.One);
            m_commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        }
        else
        {
            m_material.DisableKeyword("UNITY_HDR_ON");
            m_material.SetInt("_SrcBlend", (int)BlendMode.DstColor);
            m_material.SetInt("_DstBlend", (int)BlendMode.Zero);
            m_commands.SetRenderTarget(BuiltinRenderTextureType.GBuffer3);
        }

        if (m_edge_highlighting)
        {
            m_material.EnableKeyword("ENABLE_EDGE_HIGHLIGHTING");
        }
        else
        {
            m_material.DisableKeyword("ENABLE_EDGE_HIGHLIGHTING");
        }

        if (m_smoothness_attenuation)
        {
            m_material.EnableKeyword("ENABLE_SMOOTHNESS_ATTENUAION");
        }
        else
        {
            m_material.DisableKeyword("ENABLE_SMOOTHNESS_ATTENUAION");
        }

        m_material.SetVector("_Color", m_color);
        m_material.SetVector("_Params1", new Vector4(m_intensity, m_threshold, 1.0f / m_threshold, m_factor));
        m_material.SetVector("_Params2", new Vector4(m_edge_intensity, m_edge_threshold, 0.0f, 0.0f));
    }

}
