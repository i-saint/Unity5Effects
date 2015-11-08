using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Ist
{
    [AddComponentMenu("MassParticle/GPU Particle/Capsule Collider")]
    public class MPGPCapsuleCollider : MPGPColliderBase
    {
        public enum Direction
        {
            X, Y, Z
        }

        public Vector3 m_center;
        public float m_radius = 0.5f;
        public float m_height = 2.0f;
        public Direction m_direction = Direction.Y;
        MPGPCapsuleColliderData m_collider_data;

        public override void ActualUpdate()
        {
            MPGPImpl.BuildCapsuleCollider(ref m_collider_data, m_trans, ref m_center, m_radius, m_height, (int)m_direction, m_id);
            EachTargets((t) => { t.AddCapsuleCollider(ref m_collider_data); });
        }

        void OnDrawGizmos()
        {
            if (!enabled) return;
            m_trans = GetComponent<Transform>();
            MPGPImpl.BuildCapsuleCollider(ref m_collider_data, m_trans, ref m_center, m_radius, m_height, (int)m_direction, m_id);
            Gizmos.color = MPGPImpl.ColliderGizmoColor;
            Gizmos.DrawWireSphere(m_collider_data.shape.pos1, m_radius);
            Gizmos.DrawWireSphere(m_collider_data.shape.pos2, m_radius);
            Gizmos.DrawLine(m_collider_data.shape.pos1, m_collider_data.shape.pos2);
            Gizmos.matrix = Matrix4x4.identity;
        }
    }
}
