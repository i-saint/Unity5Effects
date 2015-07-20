using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(Camera))]
[RequireComponent(typeof(GBufferUtils))]
//[ExecuteInEditMode]
public class NormalLighting : MonoBehaviour
{
    public Vector4 m_color = new Vector4(0.75f, 0.75f, 1.25f, 0.0f);
    public float m_intensity = 1.0f;
    public float m_threshold = 0.5f;
    public float m_edge = 0.2f;
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
        m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/IstImageEffects/Shaders/NormalLighting.shader");
        m_quad = GenerateQuad();
    }
#endif // UNITY_EDITOR

    void Update()
    {
    }

    void OnPreRender()
    {
        if (!gameObject.activeInHierarchy && !enabled) { return; }

        if (m_commands == null)
        {
            m_material = new Material(m_shader);
            m_commands = new CommandBuffer();
            m_commands.name = "NormalLighting";

            var cam = GetComponent<Camera>();
            cam.AddCommandBuffer(CameraEvent.AfterLighting, m_commands);

            m_commands.DrawMesh(m_quad, Matrix4x4.identity, m_material, 0, 0);
        }

        m_material.SetVector("_BaseColor", m_color);
        m_material.SetFloat("_Intensity", m_intensity);
        m_material.SetFloat("_Threshold", m_threshold);
        m_material.SetFloat("_Edge", m_edge);
    }

}
