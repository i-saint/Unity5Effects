using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[AddComponentMenu("Ist/Metaball Entity")]
[ExecuteInEditMode]
public class MetaballEntity : MonoBehaviour
{
    public MetaballRenderer m_renderer;
    public float m_radius = 0.25f;
    [Range(0.01f, 1.0f)] public float m_softness = 1.0f;
    public bool m_negative;
    MetaballRenderer.MetaballData m_data;


    void Update()
    {
        if(m_renderer!=null)
        {
            m_data.position = GetComponent<Transform>().position;
            m_data.radius = m_radius;
            m_data.softness = m_softness;
            m_data.negative = m_negative ? 1.0f : 0.0f;
            m_renderer.AddEntity(m_data);
        }
    }

    void OnDrawGizmos()
    {
        if (!enabled) return;
        Transform t = GetComponent<Transform>();
        Gizmos.color = Color.blue;
        Gizmos.DrawWireSphere(t.position, m_radius);
    }
}

