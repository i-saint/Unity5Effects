using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

public class WaterCausticsEntity : MonoBehaviour
{
    static List<WaterCausticsEntity> s_instances;
    static bool s_dirty;

    public static List<WaterCausticsEntity> instances
    {
        get
        {
            if (s_instances == null) s_instances = new List<WaterCausticsEntity>();
            return s_instances;
        }
    }
    public static bool dirty
    {
        get { return s_dirty; }
        set { s_dirty = value; }
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

    void OnDrawGizmos()
    {
        if (!enabled || m_mesh == null) return;
        Gizmos.matrix = GetMatrix();
        Gizmos.DrawMesh(m_mesh);
    }
}
