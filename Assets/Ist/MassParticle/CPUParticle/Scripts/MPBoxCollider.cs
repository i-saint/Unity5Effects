using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Ist
{
    [AddComponentMenu("MassParticle/CPU Particle/Box Collider")]
    public class MPBoxCollider : MPCollider
    {
        public Vector3 m_center;
        public Vector3 m_size = Vector3.one;

        public override void MPUpdate()
        {
            base.MPUpdate();

            Matrix4x4 mat = m_trans.localToWorldMatrix;
            EachTargets((w) =>
            {
                MPAPI.mpAddBoxCollider(w.GetContext(), ref m_cprops, ref mat, ref m_center, ref m_size);
            });
        }

        void OnDrawGizmos()
        {
            if (!enabled) return;
            Transform t = GetComponent<Transform>(); // エディタから実行されるので trans は使えない
            Gizmos.color = MPImpl.ColliderGizmoColor;
            Gizmos.matrix = t.localToWorldMatrix;
            Gizmos.DrawWireCube(m_center, m_size);
            Gizmos.matrix = Matrix4x4.identity;
        }
    }
}
