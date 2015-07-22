using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

namespace Ist
{
    public class WaterCausticsField : MonoBehaviour
    {
        static List<WaterCausticsField> s_instances;

        public static List<WaterCausticsField> instances
        {
            get
            {
                if (s_instances == null) s_instances = new List<WaterCausticsField>();
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