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
    [System.Serializable]
    public struct StringFloatPair
    {
        public string key;
        public float value;
    }

    static uint s_idgen;

    public float m_local_time;
    public uint m_id;
    public StringFloatPair[] m_params;

    MaterialPropertyBlock m_mpb;
    Renderer m_renderer;
    Transform m_trans;

    public virtual void LateUpdate()
    {
        if(m_id==0)
        {
            m_id = ++s_idgen;
        }
        m_local_time += Time.deltaTime;

        if (m_mpb == null)
        {
            m_renderer = GetComponent<Renderer>();
            m_trans = GetComponent<Transform>();
            m_mpb = new MaterialPropertyBlock();
            m_mpb.AddVector("_Position", Vector4.zero);
            m_mpb.AddVector("_Rotation", Vector4.zero);
            m_mpb.AddVector("_Scale", Vector4.one);
            m_mpb.AddFloat("_LocalTime", m_local_time);
            m_mpb.AddFloat("_ID", m_id);
        }

        var rot = m_trans.rotation;
        m_mpb.SetVector("_Position", m_trans.position);
        m_mpb.SetVector("_Rotation", new Vector4(rot.x, rot.y, rot.z, rot.w));
        m_mpb.SetVector("_Scale", m_trans.localScale);
        m_mpb.SetFloat("_LocalTime", m_local_time);
        for (int i = 0; i < m_params.Length; ++i)
        {
            m_mpb.SetFloat(m_params[i].key, m_params[i].value);
        }
        m_renderer.SetPropertyBlock(m_mpb);
    }
}
