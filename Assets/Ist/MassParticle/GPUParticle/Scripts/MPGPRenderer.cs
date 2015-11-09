using System.Collections;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


namespace Ist
{
    [AddComponentMenu("MassParticle/GPU Particle/Renderer")]
    [RequireComponent(typeof(MPGPWorld))]
    public class MPGPRenderer : BatchRendererBase
    {
        MPGPWorld m_world;
    
    #if UNITY_EDITOR
        void Reset()
        {
            m_mesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Foundation/Meshes/Cube.asset");
            m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/MassParticle/GPUParticle/Materials/MPGPStandard.mat");
            m_bounds_size = Vector3.one * 2.0f;
        }
    #endif // UNITY_EDITOR
    
    
    
        public override Material CloneMaterial(Material src, int nth)
        {
            Material m = new Material(src);
            m.SetInt("g_batch_begin", nth * m_instances_par_batch);
            m.SetBuffer("particles", m_world.GetParticleBuffer());
    
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
            ForEachEveryMaterials((v) =>
            {
                v.SetInt("g_num_max_instances", m_max_instances);
                v.SetInt("g_num_instances", m_instance_count);
            });
        }
    
    
        public override void OnEnable()
        {
            m_world = GetComponent<MPGPWorld>();
            m_max_instances = m_world.GetNumMaxParticles();
    
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
}
