using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


[AddComponentMenu("BooleanRenderer/Renderer")]
[RequireComponent(typeof(Camera))]
public class BooleanRenderer : MonoBehaviour
{
    public bool m_enable_piercing = true;

    CommandBuffer m_cb_backdepth;
    CommandBuffer m_cb_gbuffer;


    void OnEnable()
    {
        if (m_cb_backdepth == null)
        {
            m_cb_backdepth = new CommandBuffer();
            m_cb_backdepth.name = "BooleanSubtractRenderer: BackDepth";

            m_cb_gbuffer = new CommandBuffer();
            m_cb_gbuffer.name = "BooleanSubtractRenderer: GBuffer";
        }

        var cam = GetComponent<Camera>();
        cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_backdepth);
    }

    void OnDisable()
    {
        var cam = GetComponent<Camera>();
        cam.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_backdepth);
    }

    void OnPreRender()
    {
        int num_subtractor = IBooleanSubtractor.instances.Count;
        int num_subtracted = IBooleanSubtracted.instances.Count;
        int id_backdepth = Shader.PropertyToID("BooleanRenderer_BackDepth");

        m_cb_backdepth.Clear();
        m_cb_backdepth.GetTemporaryRT(id_backdepth, -1, -1, 32, FilterMode.Point, RenderTextureFormat.RHalf);
        m_cb_backdepth.SetRenderTarget(id_backdepth);
        m_cb_backdepth.ClearRenderTarget(true, true, Color.black, 0.0f);
        m_cb_backdepth.SetGlobalTexture("_BackDepth", id_backdepth);
        for (int i = 0; i < num_subtracted; ++i)
        {
            IBooleanSubtracted.instances[i].IssueDrawCall_BackDepth(m_cb_backdepth);
        }

        m_cb_gbuffer.Clear();
        for (int i = 0; i < num_subtracted; ++i)
        {
            IBooleanSubtracted.instances[i].IssueDrawCall_GBuffer(m_cb_gbuffer);
        }
        for (int i = 0; i < num_subtractor; ++i)
        {
            IBooleanSubtractor.instances[i].IssueDrawCall_GBuffer(m_cb_gbuffer);
        }
    }
}
