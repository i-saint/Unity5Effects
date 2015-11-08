using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Ist
{
    [AddComponentMenu("MassParticle/GPU Particle/Sphere Collider")]
    public class MPGPSphereCollider : MPGPColliderBase
    {
        public Vector3 m_center;
        public float m_radius = 0.5f;
        MPGPSphereColliderData m_collider_data;
    
        public override void ActualUpdate()
        {
            MPGPImpl.BuildSphereCollider(ref m_collider_data, m_trans, ref m_center, m_radius, m_id);
            EachTargets((t) => { t.AddSphereCollider(ref m_collider_data); });
        }
    
        void OnDrawGizmos()
        {
            if (!enabled) return;
            Transform t = GetComponent<Transform>(); // エディタから実行されるので trans は使えない
            Gizmos.color = MPGPImpl.ColliderGizmoColor;
            Gizmos.matrix = t.localToWorldMatrix;
            Gizmos.DrawWireSphere(m_center, m_radius);
            Gizmos.matrix = Matrix4x4.identity;
        }
    
    }
}
