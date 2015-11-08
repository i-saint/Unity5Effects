using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;

namespace Ist
{
    [AddComponentMenu("MassParticle/CPU Particle/World")]
    public class MPWorld : MonoBehaviour
    {
        public static List<MPWorld> s_instances = new List<MPWorld>();
        public static MPWorld s_current;
        static int s_update_count = 0;

        void EachWorld(Action<MPWorld> f)
        {
            s_instances.ForEach(f);
        }
        public static MPWorld GetCurrent() { return s_current; }
        public static int GetCurrentContext() { return s_current.GetContext(); }


        public const int CubeBatchSize = 2700;
        public const int PointBatchSize = 65000;
        public const int DataTextureWidth = 3072;
        public const int DataTextureHeight = 256;

        public MPUpdateMode m_update_mode = MPUpdateMode.Deferred;
        public MPSolverType m_solver = MPSolverType.Impulse;
        public bool m_enable_interaction = true;
        public bool m_enable_colliders = true;
        public bool m_enable_forces = true;
        public bool m_id_as_float = true;
        public float m_particle_mass = 0.1f;
        public float m_timescale = 0.6f;
        public float m_damping = 0.6f;
        public float m_advection = 0.1f;
        public float m_pressure_stiffness = 500.0f;
        public float m_particle_size = 0.08f;
        public int m_max_particle_num = 100000;
        public Vector3 m_coord_scale = Vector3.one;
        public int m_world_div_x = 256;
        public int m_world_div_y = 1;
        public int m_world_div_z = 256;
        public Vector3 m_active_region_center = Vector3.zero;
        public Vector3 m_active_region_extent = Vector3.zero;
        public int m_particle_num = 0;
        public int m_context = 0;

        List<Action> m_actions = new List<Action>();
        List<Action> m_onetime_actions = new List<Action>();
        RenderTexture m_instance_texture;
        bool m_texture_needs_update;



        public int GetContext() { return m_context; }
        public void AddUpdateRoutine(Action a) { m_actions.Add(a); }
        public void RemoveUpdateRoutine(Action a) { m_actions.Remove(a); }
        public void AddOneTimeAction(Action a) { m_onetime_actions.Add(a); }

        public RenderTexture GetInstanceTexture()
        {
            UpdateInstanceTexture();
            return m_instance_texture;
        }

        public void UpdateInstanceTexture()
        {
            if (m_instance_texture == null)
            {
                m_instance_texture = new RenderTexture(MPWorld.DataTextureWidth, MPWorld.DataTextureHeight, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Default);
                m_instance_texture.filterMode = FilterMode.Point;
                m_instance_texture.Create();
            }
            if (m_texture_needs_update)
            {
                m_texture_needs_update = false;
                MPAPI.mpUpdateDataTexture(GetContext(), m_instance_texture.GetNativeTexturePtr(), m_instance_texture.width, m_instance_texture.height);
            }
        }



        MPWorld()
        {
#if UNITY_EDITOR_WIN || UNITY_STANDALONE_WIN
            MPAPI.mphInitialize();
#endif
        }



        void Awake()
        {
            m_context = MPAPI.mpCreateContext();
        }

        void OnDestroy()
        {
            MPAPI.mpDestroyContext(GetContext());
            if (m_instance_texture != null)
            {
                m_instance_texture.Release();
                m_instance_texture = null;
            }
        }

        void OnEnable()
        {
            s_instances.Add(this);
        }

        void OnDisable()
        {
            s_instances.Remove(this);
        }



        void Update()
        {
            if (s_update_count++ == 0)
            {
                if (Time.deltaTime != 0.0f)
                {
                    ActualUpdate();
                }
            }
        }


        void LateUpdate()
        {
            --s_update_count;
        }



        static void ActualUpdate()
        {
            if (s_instances.Count == 0) { return; }
            if (s_instances[0].m_update_mode == MPUpdateMode.Immediate)
            {
                ImmediateUpdate();
            }
            else if (s_instances[0].m_update_mode == MPUpdateMode.Deferred)
            {
                DeferredUpdate();
            }
        }

        static void ImmediateUpdate()
        {
            foreach (MPWorld w in s_instances)
            {
                w.UpdateKernelParams();
            }
            UpdateMPObjects();
            foreach (MPWorld w in s_instances)
            {
                MPAPI.mpUpdate(w.GetContext(), Time.deltaTime);
                s_current = w;
                MPAPI.mpCallHandlers(w.GetContext());
                MPAPI.mpClearCollidersAndForces(w.GetContext());
                w.CallUpdateRoutines();
                s_current = null;
            }
        }

        static void DeferredUpdate()
        {
            foreach (MPWorld w in s_instances)
            {
                MPAPI.mpEndUpdate(w.GetContext());
            }
            foreach (MPWorld w in s_instances)
            {
                s_current = w;
                MPAPI.mpCallHandlers(w.GetContext());
                MPAPI.mpClearCollidersAndForces(w.GetContext());
                w.CallUpdateRoutines();
                w.UpdateKernelParams();
                s_current = null;
            }
            UpdateMPObjects();
            foreach (MPWorld w in s_instances)
            {
                MPAPI.mpBeginUpdate(w.GetContext(), Time.deltaTime);
            }
        }

        void CallUpdateRoutines()
        {
            m_actions.ForEach((a) => { a.Invoke(); });
            m_onetime_actions.ForEach((a) => { a.Invoke(); });
            m_onetime_actions.Clear();
        }


        void OnDrawGizmos()
        {
            if (!enabled) return;
            Gizmos.color = MPImpl.WorldGizmoColor;
            Gizmos.DrawWireCube(transform.position, transform.localScale * 2.0f);
            Gizmos.DrawWireCube(transform.position + m_active_region_center, m_active_region_extent * 2.0f);
        }


        void UpdateKernelParams()
        {
            m_texture_needs_update = true;

            m_particle_num = MPAPI.mpGetNumParticles(GetContext());

            MPKernelParams p = MPAPI.mpGetKernelParams(GetContext());
            p.world_center = transform.position;
            p.world_size = transform.localScale;
            p.world_div_x = m_world_div_x;
            p.world_div_y = m_world_div_y;
            p.world_div_z = m_world_div_z;
            p.active_region_center = transform.position + m_active_region_center;
            p.active_region_extent = m_active_region_extent;
            p.solver_type = (int)m_solver;
            p.enable_interaction = m_enable_interaction ? 1 : 0;
            p.enable_colliders = m_enable_colliders ? 1 : 0;
            p.enable_forces = m_enable_forces ? 1 : 0;
            p.id_as_float = m_id_as_float ? 1 : 0;
            p.timestep = Time.deltaTime * m_timescale;
            p.damping = m_damping;
            p.advection = m_advection;
            p.pressure_stiffness = m_pressure_stiffness;
            p.scaler = m_coord_scale;
            p.particle_size = m_particle_size;
            p.max_particles = m_max_particle_num;
            MPAPI.mpSetKernelParams(GetContext(), ref p);
        }

        static void UpdateMPObjects()
        {
            MPCollider.MPUpdateAll();
            MPForce.MPUpdateAll();
            MPEmitter.MPUpdateAll();
        }

    }

}
