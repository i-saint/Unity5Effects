using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[AddComponentMenu("Ist/Metaball Renderer")]
[RequireComponent(typeof(Renderer))]
[ExecuteInEditMode]
public class MetaballRenderer : MonoBehaviour
{
    public struct MetaballData
    {
        public const int size = 32;

        public Vector3 position;
        public float radius;
        public float softness;
        public float negative;
        public float pad1;
        public float pad2;
    }

    public class SortByNegative : IComparer<MetaballData>
    {
        public int Compare(MetaballData a, MetaballData b)
        {
            return a.negative.CompareTo(b.negative);
        }
    }


    public int m_max_entities = 32;
    int m_num_entities = 0;
    MetaballData[] m_entities;
    ComputeBuffer m_buffer;
    Material m_material;
    bool m_needs_sort = false;

    public void AddEntity(MetaballData e)
    {
        InitializeMembers();
        int i = m_num_entities++;
        if (i < m_max_entities)
        {
            m_entities[i] = e;
            m_needs_sort = m_needs_sort || e.negative != 0.0f;
        }
    }

    void InitializeMembers()
    {
        if (m_entities == null)
        {
            m_entities = new MetaballData[m_max_entities];
            m_buffer = new ComputeBuffer(m_max_entities, MetaballData.size);
            m_material = GetComponent<Renderer>().sharedMaterial;
        }
    }

    void OnDestroy()
    {
        if (m_buffer != null)
        {
            m_buffer.Release();
            m_buffer = null;
        }
    }

    void LateUpdate()
    {
        InitializeMembers();

        if(m_needs_sort)
        {
            // negative metaballs should be rendered after all positive metaballs.
            System.Array.Sort(m_entities, 0, m_num_entities, new SortByNegative());
            m_needs_sort = false;
        }

        m_buffer.SetData(m_entities);
        m_material.SetBuffer("_Entities", m_buffer);
        m_material.SetInt("_NumEntities", Mathf.Min(m_num_entities, m_max_entities));
        m_num_entities = 0;
    }
}

