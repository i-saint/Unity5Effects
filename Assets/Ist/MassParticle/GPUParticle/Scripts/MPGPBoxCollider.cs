using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Ist
{
    [AddComponentMenu("MassParticle/GPU Particle/Box Collider")]
    public class MPGPBoxCollider : MPGPColliderBase
    {
        public Vector3 m_center;
        public Vector3 m_size = Vector3.one;
        MPGPBoxColliderData m_collider_data;
    
        public override void ActualUpdate()
        {
            MPGPImpl.BuildBoxCollider(ref m_collider_data, m_trans, ref m_center, ref m_size, m_id);
            EachTargets((t) => { t.AddBoxCollider(ref m_collider_data); });
        }
    
        void OnDrawGizmos()
        {
            if (!enabled) return;
            Transform t = GetComponent<Transform>();
            Gizmos.color = MPGPImpl.ColliderGizmoColor;
            Gizmos.matrix = t.localToWorldMatrix;
            Gizmos.DrawWireCube(m_center, m_size);
            Gizmos.matrix = Matrix4x4.identity;
        }
    
    }
}