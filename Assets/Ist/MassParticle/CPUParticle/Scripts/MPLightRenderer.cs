using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    [AddComponentMenu("MassParticle/CPU Particle/Light Renderer")]
    [RequireComponent(typeof(MPWorld))]
    public class MPLightRenderer : BatchRendererBase
    {
        public enum Sample
        {
            Fast,
            Medium,
            High,
        }
        public Color m_color = Color.white;
        public float m_intensity = 0.9f;

        public Color m_heat_color = new Color(1.0f, 0.4f, 0.2f, 0.0f);
        public float m_heat_intensity = 0.7f;
        public float m_heat_threshold = 2.0f;

        public float m_size = 1.25f;
        public bool m_enable_shadow = false;
        public Sample m_sample = Sample.Fast;
        public float m_occulusion_strength = 0.2f;

        MPWorld m_world;
        MaterialPropertyBlock m_mpb;
        CommandBuffer m_cb;
        Camera[] m_cameras;
        bool m_hdr = true;

#if UNITY_EDITOR
        void Reset()
        {
            m_mesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Foundation/Meshes/IcoSphere.asset");
            m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/MassParticle/CPUParticle/Materials/MPPointLight.mat");
            m_bounds_size = Vector3.one * 2.0f;
        }
#endif // UNITY_EDITOR


        public Vector4 GetLinearColor()
        {
            return new Vector4(
                Mathf.GammaToLinearSpace(m_color.r * m_intensity),
                Mathf.GammaToLinearSpace(m_color.g * m_intensity),
                Mathf.GammaToLinearSpace(m_color.b * m_intensity),
                1.0f
            );
        }

        public Vector4 GetLinearHeatColor()
        {
            return new Vector4(
                Mathf.GammaToLinearSpace(m_heat_color.r * m_heat_intensity),
                Mathf.GammaToLinearSpace(m_heat_color.g * m_heat_intensity),
                Mathf.GammaToLinearSpace(m_heat_color.b * m_heat_intensity),
                1.0f
            );
        }


        public override Material CloneMaterial(Material src, int nth)
        {
            var instance_texture = m_world.GetInstanceTexture();

            Material m = new Material(src);
            m.SetInt("g_batch_begin", nth * m_instances_par_batch);
            m.SetTexture("g_instance_data", instance_texture);

            Vector4 ts = new Vector4(
                1.0f / instance_texture.width,
                1.0f / instance_texture.height,
                instance_texture.width,
                instance_texture.height);
            m.SetVector("g_instance_data_size", ts);

            if (m_hdr)
            {
                m.SetInt("_SrcBlend", (int)BlendMode.One);
                m.SetInt("_DstBlend", (int)BlendMode.One);
            }
            else
            {
                m.SetInt("_SrcBlend", (int)BlendMode.DstColor);
                m.SetInt("_DstBlend", (int)BlendMode.Zero);
            }

            if (m_enable_shadow)
            {
                m.EnableKeyword("ENABLE_SHADOW");
                switch (m_sample)
                {
                    case Sample.Fast:
                        m.EnableKeyword("QUALITY_FAST");
                        m.DisableKeyword("QUALITY_MEDIUM");
                        m.DisableKeyword("QUALITY_HIGH");
                        break;
                    case Sample.Medium:
                        m.DisableKeyword("QUALITY_FAST");
                        m.EnableKeyword("QUALITY_MEDIUM");
                        m.DisableKeyword("QUALITY_HIGH");
                        break;
                    case Sample.High:
                        m.DisableKeyword("QUALITY_FAST");
                        m.DisableKeyword("QUALITY_MEDIUM");
                        m.EnableKeyword("QUALITY_HIGH");
                        break;
                }
            }
            else
            {
                m.DisableKeyword("ENABLE_SHADOW");
            }

            return m;
        }


        public virtual void ReleaseGPUResources()
        {
            ClearMaterials();
        }

        public virtual void ResetGPUResoures()
        {
            ReleaseGPUResources();
            UpdateGPUResources();
        }

        public override void UpdateGPUResources()
        {
            if (m_world != null)
            {
                m_world.UpdateInstanceTexture();
            }

            ForEachEveryMaterials((v) =>
            {
                v.SetInt("g_num_max_instances", m_max_instances);
                v.SetInt("g_num_instances", m_instance_count);
            });
        }

        protected override void IssueDrawCall()
        {
            if (m_cb == null)
            {
                m_cb = new CommandBuffer();
                m_cb.name = "MPLightRenderer";
                foreach (var c in m_cameras)
                {
                    if (c != null) c.AddCommandBuffer(CameraEvent.AfterLighting, m_cb);
                }

                m_mpb = new MaterialPropertyBlock();
                m_mpb.AddColor("_Color", GetLinearColor());

            }
            m_cb.Clear();

            if (m_hdr)
            {
                m_cb.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
            }
            else
            {
                m_cb.SetRenderTarget(BuiltinRenderTextureType.GBuffer3);
            }
            m_mpb.SetColor("_Color", GetLinearColor());
            m_mpb.SetFloat("g_size", m_size);
            m_mpb.SetFloat("_OcculusionStrength", m_occulusion_strength);
            m_mpb.SetColor("_HeatColor", GetLinearHeatColor());
            m_mpb.SetFloat("_HeatThreshold", m_heat_threshold);

            Matrix4x4 matrix = Matrix4x4.identity;
            m_actual_materials.ForEach(a =>
            {
                for (int i = 0; i < m_batch_count; ++i)
                {
                    m_cb.DrawMesh(m_expanded_mesh, matrix, a[i], 0, 0, m_mpb);
                }
            });
        }



        public override void OnEnable()
        {
            m_world = GetComponent<MPWorld>();
            m_max_instances = m_world.m_max_particle_num;
            m_cameras = m_camera == null ? Camera.allCameras : new Camera[] { m_camera };

            if (m_cameras.Length > 0)
            {
                m_hdr = m_cameras[0].hdr;
            }

            base.OnEnable();
            ResetGPUResoures();
        }

        public override void OnDisable()
        {
            base.OnDisable();
            ReleaseGPUResources();

            foreach (var c in m_cameras)
            {
                if (c != null) c.RemoveCommandBuffer(CameraEvent.AfterLighting, m_cb);
            }
            m_cameras = null;

            if (m_cb != null)
            {
                m_cb.Release();
                m_cb = null;
            }
        }

        public override void LateUpdate()
        {
            if (m_world != null)
            {
                m_instance_count = m_max_instances;
                base.LateUpdate();
            }
        }

        public override void OnDrawGizmos()
        {
        }
    }

}
