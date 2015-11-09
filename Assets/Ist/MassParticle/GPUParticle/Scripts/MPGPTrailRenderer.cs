using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif


namespace Ist
{
    [AddComponentMenu("MassParticle/GPU Particle/Trail Renderer")]
    [RequireComponent(typeof(MPGPWorld))]
    public class MPGPTrailRenderer : BatchRendererBase
    {
        public int m_max_trail_history = 8;
        public float m_samples_per_second = 8.0f;
        public ComputeShader m_cs_trail;
    
        ComputeBuffer m_buf_trail_params;
        ComputeBuffer m_buf_trail_entities;
        ComputeBuffer m_buf_trail_history;
        ComputeBuffer m_buf_trail_vertices;
    
        MPGPWorld m_world;
        MPGPTrailParams[] m_tmp_params;
        System.Action m_act_render;
        int m_max_entities;
        bool m_first = true;
    
        const int BLOCK_SIZE = 512;
    
    #if UNITY_EDITOR
        void Reset()
        {
            m_cs_trail = AssetDatabase.LoadAssetAtPath<ComputeShader>("Assets/Ist/MassParticle/GPUParticle/Shaders/MPGPTrail.compute");
            m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/MassParticle/GPUParticle/Materials/MPGPTrail.mat");
            m_bounds_size = Vector3.one * 2.0f;
        }
    
        void OnValidate()
        {
            m_max_trail_history = Mathf.Max(m_max_trail_history, 2);
        }
    #endif // UNITY_EDITOR
    
    
        public override Material CloneMaterial(Material src, int nth)
        {
            Material m = new Material(src);
    
            m.SetInt("g_batch_begin", nth * m_instances_par_batch);
            m.SetBuffer("particles", m_world.GetParticleBuffer());
            m.SetBuffer("params", m_buf_trail_params);
            m.SetBuffer("vertices", m_buf_trail_vertices);
    
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
    
            if (m_buf_trail_vertices != null)
            {
                m_buf_trail_vertices.Release();
                m_buf_trail_vertices = null;
            }
            if (m_buf_trail_history != null)
            {
                m_buf_trail_history.Release();
                m_buf_trail_history = null;
            }
            if (m_buf_trail_entities != null)
            {
                m_buf_trail_entities.Release();
                m_buf_trail_entities = null;
            }
            if (m_buf_trail_params != null)
            {
                m_buf_trail_params.Release();
                m_buf_trail_params = null;
            }
        }
    
        public virtual void ResetGPUResoures()
        {
            ReleaseGPUResources();
    
            m_buf_trail_params = new ComputeBuffer(1, MPGPTrailParams.size);
            m_buf_trail_entities = new ComputeBuffer(m_max_entities, MPGPTrailEntity.size);
            m_buf_trail_history = new ComputeBuffer(m_max_entities * m_max_trail_history, MPGPTrailHistory.size);
            m_buf_trail_vertices = new ComputeBuffer(m_max_entities * m_max_trail_history, MPGPTrailVertex.size);
            {
                int[] indices = new int[(m_max_trail_history - 1) * 6];
                int[] ls = new int[6]{0,3,1, 0,2,3};
                for (int i = 0; i < m_max_trail_history - 1; ++i )
                {
                    indices[i * 6 + 0] = i * 2 + ls[0];
                    indices[i * 6 + 1] = i * 2 + ls[1];
                    indices[i * 6 + 2] = i * 2 + ls[2];
                    indices[i * 6 + 3] = i * 2 + ls[3];
                    indices[i * 6 + 4] = i * 2 + ls[4];
                    indices[i * 6 + 5] = i * 2 + ls[5];
                }
                m_expanded_mesh = BatchRendererUtil.CreateIndexOnlyMesh(m_max_trail_history * 2, indices, out m_instances_par_batch);
            }
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
            m_tmp_params = new MPGPTrailParams[1];
    
            m_max_entities = m_world.GetNumMaxParticles() * 2;
    
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
            if (!enabled || !m_world.enabled || Time.deltaTime == 0.0f) return;
            if (m_first)
            {
                m_first = false;
                DispatchTrailKernel(0);
            }
            DispatchTrailKernel(1);
    
            m_instance_count = m_max_instances;
            Transform t = m_world.GetComponent<Transform>();
            Vector3 min = t.position - t.localScale;
            Vector3 max = t.position + t.localScale;
            m_expanded_mesh.bounds = new Bounds(min, max);
            base.LateUpdate();
        }
    
        void DispatchTrailKernel(int i)
        {
            m_tmp_params[0].delta_time = Time.deltaTime;
            m_tmp_params[0].max_entities = m_max_entities;
            m_tmp_params[0].max_history = m_max_trail_history;
            m_tmp_params[0].interval = 1.0f / m_samples_per_second;
            m_buf_trail_params.SetData(m_tmp_params);
    
            m_cs_trail.SetBuffer(i, "particles", m_world.GetParticleBuffer());
            m_cs_trail.SetBuffer(i, "params", m_buf_trail_params);
            m_cs_trail.SetBuffer(i, "entities", m_buf_trail_entities);
            m_cs_trail.SetBuffer(i, "history", m_buf_trail_history);
            m_cs_trail.SetBuffer(i, "vertices", m_buf_trail_vertices);
            m_cs_trail.Dispatch(i, m_world.m_max_particles/BLOCK_SIZE, 1, 1);
        }
    
        public override void OnDrawGizmos()
        {
        }
    }
}
