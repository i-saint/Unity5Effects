using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Ist
{

    [AddComponentMenu("MassParticle/CPU Particle/Renderer")]
    [RequireComponent(typeof(MPWorld))]
    public class MPRenderer : BatchRendererBase
    {
        MPWorld m_world;
        Bounds m_bounds;


#if UNITY_EDITOR
        void Reset()
        {
            m_mesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Foundation/Meshes/Cube.asset");
            m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/MassParticle/CPUParticle/Materials/MPStandard.mat");
            m_bounds_size = Vector3.one * 2.0f;
        }
#endif


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

            // fix rendering order for transparent objects
            if (m.renderQueue >= 3000)
            {
                m.renderQueue = m.renderQueue + (nth + 1);
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

}
