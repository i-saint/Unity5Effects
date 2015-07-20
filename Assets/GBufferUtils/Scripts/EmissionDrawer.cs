using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

public abstract class IDrawer<T> : MonoBehaviour
{
    #region static
    static HashSet<IDrawer<T>> s_instances;
    static CommandBuffer s_commandbuffer;
    static HashSet<Camera> s_cameras;
    static int s_nth;

    static public HashSet<IDrawer<T>> GetInstances()
    {
        if (s_instances == null) { s_instances = new HashSet<IDrawer<T>>(); }
        return s_instances;
    }

    static public CommandBuffer GetCommandBuffer()
    {
        if (s_commandbuffer == null) { s_commandbuffer = new CommandBuffer(); }
        return s_commandbuffer;
    }

    static public HashSet<Camera> GetCameraTable()
    {
        if (s_cameras == null) { s_cameras = new HashSet<Camera>(); }
        return s_cameras;
    }

    static public void IssueDrawCallAll(CommandBuffer commands)
    {
        foreach (var i in GetInstances()) { i.IssueDrawCall(commands); }
    }
    #endregion

    public virtual void OnEnable()
    {
        GetInstances().Add(this);
    }

    public virtual void OnDisable()
    {
        var intances = GetInstances();
        intances.Remove(this);

        if (intances.Count == 0)
        {
            var cb = GetCommandBuffer();
            var cam_table = GetCameraTable();
            foreach (var c in cam_table)
            {
                if (c != null)
                {
                    c.RemoveCommandBuffer(CameraEvent.AfterGBuffer, cb);
                }
            }
            cam_table.Clear();
        }
    }

    public virtual void LateUpdate()
    {
        s_nth = 0;
    }

    public virtual void OnWillRenderObject()
    {
        if(s_nth++==0) {
            var cam = Camera.current;
            if (cam == null) { return; }

            var cb = GetCommandBuffer();
            var cam_table = GetCameraTable();
            if (!cam_table.Contains(cam))
            {
                cb.name = GetCommandBufferName();
                cam.AddCommandBuffer(CameraEvent.AfterGBuffer, cb);
                cam_table.Add(cam);
            }

            UpdateCommandBuffer(cb);
        }
    }

    public virtual string GetCommandBufferName() { return "IDrawer<T>"; }
    public abstract void IssueDrawCall(CommandBuffer commands);
    public abstract void UpdateCommandBuffer(CommandBuffer commands);
}



[AddComponentMenu("GBufferUtils/EmissionDrawer")]
[RequireComponent(typeof(Renderer))]
[ExecuteInEditMode]
public class EmissionDrawer : IDrawer<EmissionDrawer>
{
    public Material[] m_materials;

#if UNITY_EDITOR
    void Reset()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/GBufferUtils/Materials/Depth.mat");
        int num_materials = GetComponent<Renderer>().sharedMaterials.Length;
        m_materials = new Material[num_materials];
        for (int i = 0; i < m_materials.Length; ++i)
        {
            m_materials[i] = mat;
        }
    }
#endif // UNITY_EDITOR

    public override string GetCommandBufferName() { return "EmissionDrawer"; }

    public override void IssueDrawCall(CommandBuffer commands)
    {
        if (!gameObject.activeInHierarchy && !enabled) { return; }

        var renderer = GetComponent<Renderer>();
        for (int i = 0; i < m_materials.Length; ++i)
        {
            commands.DrawRenderer(renderer, m_materials[i], i, 0);
        }
    }

    public override void UpdateCommandBuffer(CommandBuffer commands)
    {
        commands.Clear();
        commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        IssueDrawCallAll(commands);
    }
}
