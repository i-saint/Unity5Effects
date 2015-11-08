using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Ist
{
    [AddComponentMenu("MassParticle/CPU Particle/Sphere Collider")]
    public class MPSphereCollider : MPCollider
    {
        public Vector3 m_center;
        public float m_radius = 0.5f;


        public override void MPUpdate()
        {
            base.MPUpdate();
            Vector3 pos = m_trans.localToWorldMatrix * new Vector4(m_center.x, m_center.y, m_center.z, 1.0f);
            EachTargets((w) =>
            {
                MPAPI.mpAddSphereCollider(w.GetContext(), ref m_cprops, ref pos, m_trans.localScale.magnitude * 0.25f);
            });
        }

        void OnDrawGizmos()
        {
            if (!enabled) return;
            Transform t = GetComponent<Transform>(); // エディタから実行されるので trans は使えない
            Gizmos.color = MPImpl.ColliderGizmoColor;
            Gizmos.matrix = t.localToWorldMatrix;
            Gizmos.DrawWireSphere(m_center, 0.5f);
            Gizmos.matrix = Matrix4x4.identity;
        }

    }
}
