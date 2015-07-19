using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

public abstract class IDepthDrawer<T> : MonoBehaviour
{
    #region static
    static private HashSet<IDepthDrawer<T>> s_instances;
    static public HashSet<IDepthDrawer<T>> instances
    {
        get
        {
            if (s_instances == null) { s_instances = new HashSet<IDepthDrawer<T>>(); }
            return s_instances;
        }
    }

    static public void IssueDrawCallAll_FrontDepth(CommandBuffer commands)
    {
        foreach (var i in instances)
        {
            i.IssueDrawCall_FrontDepth(commands);
        }
    }
    static public void IssueDrawCallAll_BackDepth(CommandBuffer commands)
    {
        foreach (var i in instances)
        {
            i.IssueDrawCall_BackDepth(commands);
        }
    }
    #endregion

    void OnEnable()
    {
        instances.Add(this);
    }

    void OnDisable()
    {
        instances.Remove(this);
    }

    public abstract void IssueDrawCall_FrontDepth(CommandBuffer commands);
    public abstract void IssueDrawCall_BackDepth(CommandBuffer commands);
}


[RequireComponent(typeof(Renderer))]
public class DepthDrawer<T> : IDepthDrawer<T>
{
    public Material[] m_materials_depth;

#if UNITY_EDITOR
    void Reset()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/GBufferUtils/Materials/Depth.mat");
        int num_materials = GetComponent<Renderer>().sharedMaterials.Length;
        m_materials_depth = new Material[num_materials];
        for (int i = 0; i < m_materials_depth.Length; ++i)
        {
            m_materials_depth[i] = mat;
        }
    }
#endif // UNITY_EDITOR

    public override void IssueDrawCall_FrontDepth(CommandBuffer commands)
    {
        var renderer = GetComponent<Renderer>();
        for (int i = 0; i < m_materials_depth.Length; ++i )
        {
            commands.DrawRenderer(renderer, m_materials_depth[i], i, 1);
        }
    }

    public override void IssueDrawCall_BackDepth(CommandBuffer commands)
    {
        var renderer = GetComponent<Renderer>();
        for (int i = 0; i < m_materials_depth.Length; ++i)
        {
            commands.DrawRenderer(renderer, m_materials_depth[i], i, 0);
        }
    }
}
