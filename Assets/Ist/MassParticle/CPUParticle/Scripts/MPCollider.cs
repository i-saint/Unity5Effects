using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Ist
{
    public class MPCollider : MonoBehaviour
    {
        public static List<MPCollider> s_instances = new List<MPCollider>();
        public static List<MPCollider> s_instances_prev = new List<MPCollider>();

        public MPWorld[] m_targets;

        public bool m_receive_hit = false;
        public bool m_receive_force = false;
        public float m_stiffness = 1500.0f;

        public MPHitHandler m_hit_handler;
        public MPForceHandler m_force_handler;
        public MPColliderProperties m_cprops;

        protected Transform m_trans;
        protected Rigidbody m_rigid3d;
        protected Rigidbody2D m_rigid2d;

        protected delegate void TargetEnumerator(MPWorld world);
        protected void EachTargets(TargetEnumerator e)
        {
            if (m_targets.Length != 0)
                foreach (var w in m_targets) e(w);
            else
                foreach (var w in MPWorld.s_instances) e(w);
        }


        public static MPCollider GetHitOwner(int id)
        {
            return s_instances_prev[id];
        }

        void Awake()
        {
            if (m_hit_handler == null) m_hit_handler = PropagateHit;
            if (m_force_handler == null) m_force_handler = PropagateForce;
        }

        void OnEnable()
        {
            m_trans = GetComponent<Transform>();
            m_rigid3d = GetComponent<Rigidbody>();
            m_rigid2d = GetComponent<Rigidbody2D>();
            if (s_instances.Count == 0) s_instances.Add(null);
            s_instances.Add(this);
        }

        void OnDisable()
        {
            s_instances.Remove(this);
            EachTargets((w) =>
            {
                MPAPI.mpRemoveCollider(w.GetContext(), ref m_cprops);
            });
        }


        public virtual void MPUpdate()
        {
            m_cprops.stiffness = m_stiffness;
            m_cprops.hit_handler = m_receive_hit ? m_hit_handler : null;
            m_cprops.force_handler = m_receive_force ? m_force_handler : null;
        }

        public static void MPUpdateAll()
        {
            int i = 0;
            foreach (var o in s_instances)
            {
                if (o != null)
                {
                    o.m_cprops.owner_id = i;
                    if (o.enabled) o.MPUpdate();
                }
                ++i;
            }
            s_instances_prev = s_instances;
        }


        public unsafe void PropagateHit(ref MPParticle particle)
        {
            Vector3 f = MPAPI.mpGetIntermediateData(MPWorld.GetCurrentContext())->accel * MPWorld.GetCurrent().m_particle_mass;
            if (m_rigid3d != null)
            {
                m_rigid3d.AddForceAtPosition(f, particle.position);
            }
            if (m_rigid2d != null)
            {
                m_rigid2d.AddForceAtPosition(f, particle.position);
            }
        }

        public void PropagateForce(ref MPParticleForce force)
        {
            Vector3 pos = force.position_average;
            Vector3 f = force.force * MPWorld.GetCurrent().m_particle_mass;

            if (m_rigid3d != null)
            {
                m_rigid3d.AddForceAtPosition(f, pos);
            }
            if (m_rigid2d != null)
            {
                m_rigid2d.AddForceAtPosition(f, pos);
            }
        }
    }

}
