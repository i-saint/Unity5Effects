using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


public abstract class ISubtractor : MonoBehaviour
{
    public SubtractionRenderer[] m_renderer;

#if UNITY_EDITOR
    public virtual void Reset()
    {
        if (m_renderer == null || m_renderer.Length == 0)
        {
            m_renderer = SubtractionRenderer.instances.ToArray();
            foreach (var r in m_renderer) { r.AddSubtractor(this); }
        }
    }
#endif

    public virtual void OnEnable()
    {
        foreach (var r in m_renderer) { r.AddSubtractor(this); }
    }

    public virtual void OnDisable()
    {
        foreach (var r in m_renderer) { r.RemoveSubtractor(this); }
    }

    public abstract void IssueDrawCall_DepthMask(SubtractionRenderer br, CommandBuffer cb);
}
