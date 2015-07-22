using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace Ist
{
    public class WaterSurfaceField : MonoBehaviour
    {
        static List<WaterSurfaceField> s_instances;

        public static List<WaterSurfaceField> instances
        {
            get
            {
                if (s_instances == null) s_instances = new List<WaterSurfaceField>();
                return s_instances;
            }
        }


        public Mesh m_mesh;

        public Matrix4x4 GetMatrix() { return GetComponent<Transform>().localToWorldMatrix; }
        public Mesh GetMesh() { return m_mesh; }

        void OnEnable()
        {
            instances.Add(this);
        }

        void OnDisable()
        {
            instances.Remove(this);
        }

        //void OnDrawGizmos()
        //{
        //    if (!enabled || m_mesh == null) return;
        //    Gizmos.matrix = GetMatrix();
        //    Gizmos.DrawMesh(m_mesh);
        //}
    }
}