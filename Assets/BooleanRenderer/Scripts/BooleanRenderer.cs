using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/Renderer")]
[ExecuteInEditMode]
public class BooleanRenderer : MonoBehaviour
{
    public bool m_enable_piercing = true;
    CommandBuffer m_commands;
    RenderTargetIdentifier[] m_gbuffer_rt;
    List<Camera> m_cameras = new List<Camera>();
    bool m_dirty = true;

    void OnDisable()
    {
        if (m_commands != null)
        {
            int c = m_cameras.Count;
            for (int i = 0; i < c; ++i )
            {
                if (m_cameras[i] != null)
                {
                    m_cameras[i].RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
                }
            }
            m_cameras.Clear();
        }
    }

    void Update()
    {
        m_dirty = true;
    }

    void OnWillRenderObject()
    {
        if (!gameObject.activeInHierarchy && !enabled) { return; }

        var cam = Camera.current;
        if (!cam) { return; }

        UpdateCommandBuffer();

        if (!m_cameras.Contains(cam))
        {
            cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_commands);
            m_cameras.Add(cam);
        }
    }

    void UpdateCommandBuffer()
    {
        if (!m_dirty) { return; }
        m_dirty = false;

        int num_subtractor = IBooleanSubtractor.instances.Count;
        int num_subtracted = IBooleanSubtracted.instances.Count;
        int id_backdepth = Shader.PropertyToID("BooleanRenderer_BackDepth");

        if (m_commands == null)
        {
            m_commands = new CommandBuffer();
            m_commands.name = "BooleanRenderer";
            m_gbuffer_rt = new RenderTargetIdentifier[]
            {
                BuiltinRenderTextureType.GBuffer0,
                BuiltinRenderTextureType.GBuffer1,
                BuiltinRenderTextureType.GBuffer2,
                BuiltinRenderTextureType.CameraTarget,
            };
        }

        m_commands.Clear();
        if (m_enable_piercing)
        {
            m_commands.GetTemporaryRT(id_backdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.RHalf);
            m_commands.SetRenderTarget(id_backdepth);
            m_commands.ClearRenderTarget(true, true, Color.black, 0.0f);
            for (int i = 0; i < num_subtracted; ++i)
            {
                IBooleanSubtracted.instances[i].IssueDrawCall_BackDepth(m_commands);
            }
            m_commands.SetGlobalTexture("_BackDepth", id_backdepth);
            m_commands.SetRenderTarget(m_gbuffer_rt, BuiltinRenderTextureType.CameraTarget);
        }

        for (int i = 0; i < num_subtracted; ++i)
        {
            IBooleanSubtracted.instances[i].IssueDrawCall_DepthMask(m_commands);
        }
        for (int i = 0; i < num_subtractor; ++i)
        {
            IBooleanSubtractor.instances[i].IssueDrawCall_DepthMask(m_commands);
        }
    }
}
