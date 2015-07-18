using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

public abstract class ISubtracted : MonoBehaviour
{
    public SubtractionRenderer[] m_renderer;

    public virtual void OnEnable()
    {
        foreach (var r in m_renderer) { r.AddSubtracted(this); }
    }

    public virtual void OnDisable()
    {
        foreach (var r in m_renderer) { r.RemoveSubtracted(this); }
    }

    public virtual void Update()
    {
        if (m_renderer == null || m_renderer.Length == 0)
        {
            m_renderer = SubtractionRenderer.instances.ToArray();
            foreach (var r in m_renderer) { r.AddSubtracted(this); }
        }
    }

    public abstract void IssueDrawCall_BackDepth(SubtractionRenderer br, CommandBuffer cb);
    public abstract void IssueDrawCall_DepthMask(SubtractionRenderer br, CommandBuffer cb);
}
