using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Ist
{
    [AddComponentMenu("MassParticle/CPU Particle/Capsule Collider")]
    public class MPCapsuleCollider : MPCollider
    {
        public enum Direction
        {
            X,
            Y,
            Z,
        }
        public Direction m_direction = Direction.Y;
        public Vector3 m_center;
        public float m_radius = 0.5f;
        public float m_height = 0.5f;
        Vector4 m_pos1 = Vector4.zero;
        Vector4 m_pos2 = Vector4.zero;

        public override void MPUpdate()
        {
            Vector3 pos1_3 = m_pos1;
            Vector3 pos2_3 = m_pos2;
            base.MPUpdate();
            UpdateCapsule();
            EachTargets((w) =>
            {
                MPAPI.mpAddCapsuleCollider(w.GetContext(), ref m_cprops, ref pos1_3, ref pos2_3, m_radius);
            });
        }

        void UpdateCapsule()
        {
            Vector3 e = Vector3.zero;
            float h = Mathf.Max(0.0f, m_height - m_radius * 2.0f);
            switch (m_direction)
            {
                case Direction.X: e.Set(h * 0.5f, 0.0f, 0.0f); break;
                case Direction.Y: e.Set(0.0f, h * 0.5f, 0.0f); break;
                case Direction.Z: e.Set(0.0f, 0.0f, h * 0.5f); break;
            }
            Vector4 pos1 = new Vector4(e.x + m_center.x, e.y + m_center.y, e.z + m_center.z, 1.0f);
            Vector4 pos2 = new Vector4(-e.x + m_center.x, -e.y + m_center.y, -e.z + m_center.z, 1.0f);
            m_pos1 = m_trans.localToWorldMatrix * pos1;
            m_pos2 = m_trans.localToWorldMatrix * pos2;
        }

        void OnDrawGizmos()
        {
            if (!enabled) return;
            m_trans = GetComponent<Transform>();
            UpdateCapsule(); // エディタから実行される都合上必要
            Gizmos.color = MPImpl.ColliderGizmoColor;
            Gizmos.DrawWireSphere(m_pos1, m_radius);
            Gizmos.DrawWireSphere(m_pos2, m_radius);
            Gizmos.DrawLine(m_pos1, m_pos2);
            Gizmos.matrix = Matrix4x4.identity;
        }

    }
}
