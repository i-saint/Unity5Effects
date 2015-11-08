using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Ist
{
    [AddComponentMenu("MassParticle/CPU Particle/Force")]
    public class MPForce : MonoBehaviour
    {

        static List<MPForce> s_instances = new List<MPForce>();

        public MPWorld[] m_targets;
        public MPForceShape m_shape_type = MPForceShape.All;
        public MPForceDirection m_direction_type = MPForceDirection.Directional;
        public float m_strength_near = 10.0f;
        public float m_strength_far = 0.0f;
        public float m_range_inner = 0.0f;
        public float m_range_outer = 100.0f;
        public float m_attenuation_exp = 0.5f;
        public float m_random_seed = 0.0f;
        public float m_random_diffuse = 1.0f;
        public Vector3 m_direction = new Vector3(0.0f, -1.0f, 0.0f);
        public Vector3 m_cellsize = new Vector3(0.5f, 0.5f, 0.5f);

        MPForceProperties m_mpprops;

        delegate void TargetEnumerator(MPWorld world);
        void EachTargets(TargetEnumerator e)
        {
            if (m_targets.Length != 0)
                foreach (var w in m_targets) e(w);
            else
                foreach (var w in MPWorld.s_instances) e(w);
        }

        void OnEnable()
        {
            s_instances.Add(this);
        }

        void OnDisable()
        {
            s_instances.Remove(this);
        }

        public void MPUpdate()
        {
            m_mpprops.dir_type = m_direction_type;
            m_mpprops.shape_type = m_shape_type;
            m_mpprops.strength_near = m_strength_near;
            m_mpprops.strength_far = m_strength_far;
            m_mpprops.rcp_range = 1.0f / (m_strength_far - m_strength_near);
            m_mpprops.range_inner = m_range_inner;
            m_mpprops.range_outer = m_range_outer;
            m_mpprops.attenuation_exp = m_attenuation_exp;
            m_mpprops.random_seed = m_random_seed;
            m_mpprops.random_diffuse = m_random_diffuse;
            m_mpprops.direction = m_direction;
            m_mpprops.center = transform.position;
            m_mpprops.rcp_cellsize = new Vector3(1.0f / m_cellsize.x, 1.0f / m_cellsize.y, 1.0f / m_cellsize.z);
            Matrix4x4 mat = transform.localToWorldMatrix;
            EachTargets((w) =>
            {
                MPAPI.mpAddForce(w.GetContext(), ref m_mpprops, ref mat);
            });
        }

        public static void MPUpdateAll()
        {
            foreach (var o in s_instances)
            {
                if (o != null && o.enabled) o.MPUpdate();
            }
        }

        void OnDrawGizmos()
        {
            if (!enabled) return;
            {
                float arrowHeadAngle = 30.0f;
                float arrowHeadLength = 0.5f;
                Vector3 pos = transform.position;
                Vector3 dir = m_direction * m_strength_near * 0.5f;

                Gizmos.matrix = Matrix4x4.identity;
                Gizmos.color = MPImpl.ForceGizmoColor;
                Gizmos.DrawRay(pos, dir);

                Vector3 right = Quaternion.LookRotation(dir) * Quaternion.Euler(0, 180 + arrowHeadAngle, 0) * new Vector3(0, 0, 1);
                Vector3 left = Quaternion.LookRotation(dir) * Quaternion.Euler(0, 180 - arrowHeadAngle, 0) * new Vector3(0, 0, 1);
                Gizmos.DrawRay(pos + dir, right * arrowHeadLength);
                Gizmos.DrawRay(pos + dir, left * arrowHeadLength);
            }
            {
                Gizmos.matrix = transform.localToWorldMatrix;
                switch (m_shape_type)
                {
                    case MPForceShape.Sphere:
                        Gizmos.DrawWireSphere(Vector3.zero, 0.5f);
                        break;

                    case MPForceShape.Box:
                        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
                        break;
                }
                Gizmos.matrix = Matrix4x4.identity;
            }
        }
    }

}
