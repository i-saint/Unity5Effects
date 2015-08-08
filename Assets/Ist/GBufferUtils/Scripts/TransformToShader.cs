using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(Renderer))]
[ExecuteInEditMode]
public class TransformToShader : MonoBehaviour
{
    static uint s_idgen;

    MaterialPropertyBlock m_mpb;
    Renderer m_renderer;
    Transform m_trans;
    float m_local_time;
    uint m_id;

    public virtual void Update()
    {
        if(m_id==0)
        {
            m_id = ++s_idgen;
        }
        m_local_time += Time.deltaTime;
    }

    public virtual void OnWillRenderObject()
    {
        if(m_mpb == null) {
            m_mpb = new MaterialPropertyBlock();
            m_mpb.AddVector("_Position", Vector4.zero);
            m_mpb.AddVector("_Rotation", Vector4.zero);
            m_mpb.AddVector("_Scale", Vector4.one);
            m_mpb.AddFloat("_LocalTime", m_local_time);
            m_mpb.AddFloat("_ID", m_id);
            m_renderer = GetComponent<Renderer>();
            m_trans = GetComponent<Transform>();
        }

        var rot = m_trans.rotation;
        m_mpb.SetVector("_Position", m_trans.position);
        m_mpb.SetVector("_Rotation", new Vector4(rot.x, rot.y, rot.z, rot.w));
        m_mpb.SetVector("_Scale", m_trans.localScale);
        m_mpb.SetFloat("_LocalTime", m_local_time);
        m_renderer.SetPropertyBlock(m_mpb);
    }
}
