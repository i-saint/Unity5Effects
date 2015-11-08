using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Ist
{
    public enum CSForceShape
    {
        All,
        Sphere,
        Capsule,
        Box
    }
    
    public enum CSForceDirection
    {
        Directional,
        Radial,
        VectorField,
    }
    
    public struct CSForceInfo
    {
        public CSForceShape shape_type;
        public CSForceDirection dir_type;
        public float strength;
        public float random_seed;
        public float random_diffuse;
        public Vector3 direction;
        public Vector3 center;
        public Vector3 rcp_cellsize;
    }
    
    public struct CSForce
    {
        public const int size = 208;
    
        public CSForceInfo info;
        public MPGPSphere sphere;
        public MPGPCapsule capsule;
        public MPGPBox box;
    }
    
    
    [AddComponentMenu("MassParticle/GPU Particle/Force")]
    public class MPGPForce : MonoBehaviour
    {
        static List<MPGPForce> s_instances;
    
        public static List<MPGPForce> GetInstances()
        {
            if (s_instances == null) { s_instances = new List<MPGPForce>(); }
            return s_instances;
        }
    
        public static void UpdateAll()
        {
            GetInstances().ForEach((f) => {
                f.ActualUpdate();
            });
        }
    
        public MPGPWorld[] m_targets;
        public CSForceShape m_shape_type;
        public CSForceDirection m_direction_type;
        public float m_strength_near = 5.0f;
        public float m_strength_far = 0.0f;
        public float m_range_inner = 0.0f;
        public float m_range_outer = 100.0f;
        public float m_attenuation_exp = 0.5f;
        public float m_random_diffuse = 0.0f;
        public float m_random_seed = 1.0f;
        public Vector3 m_direction = new Vector3(0.0f, -1.0f, 0.0f);
        public Vector3 m_vectorfield_cellsize = new Vector3(1.5f, 1.5f, 1.5f);
        public CSForce m_force_data;
    
        protected void EachTargets(System.Action<MPGPWorld> a)
        {
            if (m_targets.Length == 0) { MPGPWorld.GetInstances().ForEach(a); }
            else { foreach (var t in m_targets) { a(t); } }
        }
    
    
        void OnEnable()
        {
            GetInstances().Add(this);
        }
    
        void OnDisable()
        {
            GetInstances().Remove(this);
        }
    
        public void ActualUpdate()
        {
            if (!enabled) return;
    
            m_force_data.info.shape_type = m_shape_type;
            m_force_data.info.dir_type = m_direction_type;
            m_force_data.info.strength = m_strength_near;
            m_force_data.info.random_diffuse = m_random_diffuse;
            m_force_data.info.random_seed = m_random_seed;
            m_force_data.info.direction = m_direction;
            m_force_data.info.center = transform.position;
            m_force_data.info.rcp_cellsize = new Vector3(1.0f / m_vectorfield_cellsize.x, 1.0f / m_vectorfield_cellsize.y, 1.0f / m_vectorfield_cellsize.z);
            if (m_shape_type == CSForceShape.Sphere)
            {
                m_force_data.sphere.center = transform.position;
                m_force_data.sphere.radius = transform.localScale.x;
            }
            else if (m_shape_type == CSForceShape.Box)
            {
                Vector3 zero = Vector3.zero;
                Vector3 one = Vector3.one;
                Matrix4x4 m = transform.localToWorldMatrix;
                MPGPImpl.BuildBox(ref m_force_data.box, ref m, ref zero, ref one);
            }
            EachTargets((t) => { t.AddForce(ref m_force_data); });
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
                Gizmos.color = MPGPImpl.ForceGizmoColor;
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
                    case CSForceShape.Sphere:
                        Gizmos.DrawWireSphere(Vector3.zero, 0.5f);
                        break;
    
                    case CSForceShape.Box:
                        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
                        break;
                }
                Gizmos.matrix = Matrix4x4.identity;
            }
        }
    }
}
