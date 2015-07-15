using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

public abstract class IBooleanSubtracted : MonoBehaviour
{
    static private List<IBooleanSubtracted> s_instances;
    static public List<IBooleanSubtracted> instances
    {
        get
        {
            if (s_instances == null) { s_instances = new List<IBooleanSubtracted>(); }
            return s_instances;
        }
    }

    void OnEnable()
    {
        instances.Add(this);
    }

    void OnDisable()
    {
        instances.Remove(this);
    }

    public abstract void IssueDrawCall_BackDepth(CommandBuffer cb);
    public abstract void IssueDrawCall_GBuffer(CommandBuffer cb);
}
