using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    [AddComponentMenu("IstEffects/ScreenSpaceShadow/Renderer")]
    [ExecuteInEditMode]
    public class ScreenSpaceShadowRenderer : MonoBehaviour
    {
        public Shader m_light_shader;
        public Mesh m_sphere_mesh;
        Material m_material;
        CommandBuffer m_commands;
        HashSet<Camera> m_cameras = new HashSet<Camera>();


#if UNITY_EDITOR
        void Reset()
        {
            m_light_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/IstEffects/ScreenSpaceShadows/Shaders/Light.shader");
            m_sphere_mesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/IstEffects/ScreenSpaceShadows/Meshes/sphere.asset");
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
                foreach (var cam in m_cameras)
                {
                    if (cam != null)
                    {
                        cam.RemoveCommandBuffer(CameraEvent.AfterLighting, m_commands);
                    }
                }
                m_cameras.Clear();
            }
        }

        void OnPreRender()
        {
            if (!gameObject.activeInHierarchy && !enabled) { return; }

            var cam = GetComponent<Camera>();

            UpdateCommandBuffer(cam);

            if (!m_cameras.Contains(cam))
            {
                cam.AddCommandBuffer(CameraEvent.AfterLighting, m_commands);
                m_cameras.Add(cam);
            }
        }

        void OnWillRenderObject()
        {
            if (!gameObject.activeInHierarchy && !enabled) { return; }

            var cam = Camera.current;
            if (!cam) { return; }

            UpdateCommandBuffer(cam);

            if (!m_cameras.Contains(cam))
            {
#if UNITY_EDITOR
                if (cam.renderingPath != RenderingPath.DeferredShading &&
                    (cam.renderingPath == RenderingPath.UsePlayerSettings && PlayerSettings.renderingPath != RenderingPath.DeferredShading))
                {
                    Debug.Log("ScreenSpaceShadowRenderer: Rendering path must be deferred.");
                }
#endif // UNITY_EDITOR
                cam.AddCommandBuffer(CameraEvent.AfterLighting, m_commands);
                m_cameras.Add(cam);
            }
        }

        void UpdateCommandBuffer(Camera cam)
        {
            if (m_commands == null)
            {
                m_commands = new CommandBuffer();
                m_commands.name = "ScreenSpaceShadowRenderer";
            }
            if (m_material == null)
            {
                m_material = new Material(m_light_shader);
            }

            int id_pos = Shader.PropertyToID("_Position");
            int id_color = Shader.PropertyToID("_Color");
            int id_params = Shader.PropertyToID("_Params1");
            var lights = LightWithScreenSpaceShadow.instances;
            var n = lights.Count;

            m_commands.Clear();
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

            for (int i = 0; i < n; ++i)
            {
                var light = lights[i];
                if (light.m_cast_shadow)
                {
                    m_material.EnableKeyword("ENABLE_SHADOW");
                }
                else
                {
                    m_material.DisableKeyword("ENABLE_SHADOW");
                }

                switch (light.m_sample)
                {
                    case LightWithScreenSpaceShadow.Sample.Fast:
                        m_material.EnableKeyword("QUALITY_FAST");
                        break;
                    case LightWithScreenSpaceShadow.Sample.Medium:
                        m_material.EnableKeyword("QUALITY_MEDIUM");
                        break;
                    case LightWithScreenSpaceShadow.Sample.High:
                        m_material.EnableKeyword("QUALITY_HIGH");
                        break;
                }
                m_commands.SetGlobalVector(id_pos, light.GetPositionAndRadius());
                m_commands.SetGlobalVector(id_color, light.GetLinearColor());
                m_commands.SetGlobalVector(id_params, light.GetParams());
                m_commands.DrawMesh(m_sphere_mesh, light.GetTRS(), m_material, 0, (int)light.m_type);
            }
        }
    }
}