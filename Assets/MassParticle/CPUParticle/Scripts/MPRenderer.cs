using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif


[AddComponentMenu("MassParticle/Renderer")]
[RequireComponent(typeof(MPWorld))]
public class MPRenderer : BatchRendererBase
{
    MPWorld m_world;
    RenderTexture m_instance_texture;
    Bounds m_bounds;


    public RenderTexture GetInstanceTexture() { return m_instance_texture; }

#if UNITY_EDITOR
    void Reset()
    {
        m_mesh = AssetDatabase.LoadAssetAtPath("Assets/BatchRenderer/Meshes/cube.asset", typeof(Mesh)) as Mesh;
        m_material = AssetDatabase.LoadAssetAtPath("Assets/MassParticle/Materials/MPStandard.mat", typeof(Material)) as Material;
        m_bounds_size = Vector3.one * 2.0f;
    }
#endif


    public override Material CloneMaterial(Material src, int nth)
    {
        Material m = new Material(src);
        m.SetInt("g_batch_begin", nth * m_instances_par_batch);
        m.SetTexture("g_instance_data", m_instance_texture);

        Vector4 ts = new Vector4(
            1.0f / m_instance_texture.width,
            1.0f / m_instance_texture.height,
            m_instance_texture.width,
            m_instance_texture.height);
        m.SetVector("g_instance_data_size", ts);

        // fix rendering order for transparent objects
        if (m.renderQueue >= 3000)
        {
            m.renderQueue = m.renderQueue + (nth + 1);
        }
        return m;
    }


    public virtual void ReleaseGPUResources()
    {
        if (m_instance_texture != null)
        {
            m_instance_texture.Release();
            m_instance_texture = null;
        }
        ClearMaterials();
    }

    public virtual void ResetGPUResoures()
    {
        ReleaseGPUResources();

        m_instance_texture = new RenderTexture(MPWorld.DataTextureWidth, MPWorld.DataTextureHeight, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Default);
        m_instance_texture.filterMode = FilterMode.Point;
        m_instance_texture.Create();

        UpdateGPUResources();
    }

    public override void UpdateGPUResources()
    {
        if (m_world != null)
        {
            m_world.UpdateDataTexture(m_instance_texture);
        }

        ForEachEveryMaterials((v) =>
        {
            v.SetInt("g_num_max_instances", m_max_instances);
            v.SetInt("g_num_instances", m_instance_count);
        });
    }


    public override void OnEnable()
    {
        m_world = GetComponent<MPWorld>();
        m_max_instances = m_world.m_max_particle_num;

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
            m_instance_count = m_world.m_particle_num;
            base.LateUpdate();
        }
    }

    public override void OnDrawGizmos()
    {
    }
}
