using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[AddComponentMenu("ScreenSpaceShadow/Renderer")]
//[ExecuteInEditMode]
public class ScreenSpaceShadowRenderer : MonoBehaviour
{
    public Shader m_light_shader;
    public Mesh m_sphere_mesh;
    Material m_light_material;
    CommandBuffer m_commands;
    HashSet<Camera> m_cameras = new HashSet<Camera>();


#if UNITY_EDITOR
#endif // UNITY_EDITOR

    void Awake()
    {
        m_light_material = new Material(m_light_shader);
    }

    void OnDestroy()
    {
        Object.DestroyImmediate(m_light_material);
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
            cam.AddCommandBuffer(CameraEvent.AfterLighting, m_commands);
            m_cameras.Add(cam);
        }
    }

    void UpdateCommandBuffer()
    {
        if(m_commands == null)
        {
            m_commands = new CommandBuffer();
            m_commands.name = "ScreenSpaceShadowRenderer";
        }

        int id_pos = Shader.PropertyToID("_Position");
        int id_color = Shader.PropertyToID("_Color");
        int id_params = Shader.PropertyToID("_Params");
        var lights = LightWithScreenSpaceShadow.instances;
        var n = lights.Count;

        m_commands.Clear();
        for (int i = 0; i < n; ++i)
        {
            var light = lights[i];
            m_commands.SetGlobalVector(id_pos, light.GetPositionAndRadius());
            m_commands.SetGlobalVector(id_color, light.GetLinearColor());
            m_commands.SetGlobalVector(id_params, light.GetParams());
            m_commands.DrawMesh(m_sphere_mesh, light.GetTRS(), m_light_material, 0, (int)light.m_type);
        }
    }
}
