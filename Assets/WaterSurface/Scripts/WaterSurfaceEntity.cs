using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class WaterSurfaceEntity : MonoBehaviour
{
    static List<WaterSurfaceEntity> s_instances;
    static bool s_dirty;

    public static List<WaterSurfaceEntity> instances {
        get {
            if (s_instances == null) s_instances = new List<WaterSurfaceEntity>();
            return s_instances;
        }
    }
    public static bool dirty {
        get { return s_dirty; }
        set { s_dirty = value;}
    }


    public Mesh m_mesh;

    public Matrix4x4 GetMatrix() { return GetComponent<Transform>().localToWorldMatrix; }
    public Mesh GetMesh() { return m_mesh; }

    void OnEnable()
    {
        instances.Add(this);
        dirty = true;
    }

    void OnDisable()
    {
        instances.Remove(this);
        dirty = true;
    }

    void OnDrawGizmos()
    {
        if (!enabled || m_mesh == null) return;
        Gizmos.matrix = GetMatrix();
        Gizmos.DrawMesh(m_mesh);
    }
}
