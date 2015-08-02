using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("GPUParticle/Renderer")]
[RequireComponent(typeof(MPGPWorld))]
public class MPGPLightRenderer : BatchRendererBase
{
    MPGPWorld m_world;
    CommandBuffer m_cb;
    Camera[] m_cameras;
    bool m_hdr = true;

#if UNITY_EDITOR
    void Reset()
    {
        m_mesh = AssetDatabase.LoadAssetAtPath("Assets/BatchRenderer/Meshes/cube.asset", typeof(Mesh)) as Mesh;
        m_material = AssetDatabase.LoadAssetAtPath("Assets/MassParticle/GPUParticle/Materials/MPGPPointLight.mat", typeof(Material)) as Material;
        m_bounds_size = Vector3.one * 2.0f;
    }
#endif // UNITY_EDITOR



    public override Material CloneMaterial(Material src, int nth)
    {
        Material m = new Material(src);
        m.SetInt("g_batch_begin", nth * m_instances_par_batch);
        m.SetBuffer("particles", m_world.GetParticleBuffer());
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
        ForEachEveryMaterials((v) =>
        {
            v.SetInt("g_num_max_instances", m_max_instances);
            v.SetInt("g_num_instances", m_instance_count);
        });
    }

    protected override void IssueDrawCall()
    {
        if(m_cb==null)
        {
            m_cb = new CommandBuffer();
            m_cb.name = "MPGPLightRenderer";

            foreach(var c in m_cameras)
            {
                c.AddCommandBuffer(CameraEvent.AfterLighting, m_cb);
            }

        }
        m_cb.Clear();

        if (m_hdr)
        {
            m_material.SetInt("_SrcBlend", (int)BlendMode.One);
            m_material.SetInt("_DstBlend", (int)BlendMode.One);
            m_cb.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        }
        else
        {
            m_material.SetInt("_SrcBlend", (int)BlendMode.DstColor);
            m_material.SetInt("_DstBlend", (int)BlendMode.Zero);
            m_cb.SetRenderTarget(BuiltinRenderTextureType.GBuffer3);
        }


        Matrix4x4 matrix = Matrix4x4.identity;
        m_actual_materials.ForEach(a =>
        {
            for (int i = 0; i < m_batch_count; ++i)
            {
                m_cb.DrawMesh(m_expanded_mesh, matrix, a[i]);
            }
        });
    }



    public override void OnEnable()
    {
        m_world = GetComponent<MPGPWorld>();
        m_max_instances = m_world.GetNumMaxParticles();
        m_cameras = m_camera == null ? Camera.allCameras : new Camera[] { m_camera };

        if(m_cameras.Length > 0)
        {
            m_hdr = m_cameras[0];
        }

        base.OnEnable();
        ResetGPUResoures();
    }

    public override void OnDisable()
    {
        base.OnDisable();
        ReleaseGPUResources();
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
