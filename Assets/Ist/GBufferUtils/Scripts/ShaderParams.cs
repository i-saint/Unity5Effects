using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[AddComponentMenu("Ist/Shader Params")]
[RequireComponent(typeof(Renderer))]
[ExecuteInEditMode]
public class ShaderParams : MonoBehaviour
{
    [System.Serializable]
    public class StringBoolPair
    {
        public string key;
        public bool value;
    }

    [System.Serializable]
    public class StringFloatPair
    {
        public string key;
        public float value;
    }

    static uint s_idgen;

    public bool m_debug_log = false;
    public bool m_use_root_position = false;
    public bool m_use_root_rotation = false;
    public bool m_use_root_scale = false;
    public float m_local_time;
    public List<StringFloatPair> m_fparams = new List<StringFloatPair>();

    uint m_id;
    MaterialPropertyBlock m_mpb;

    public void AssignParams()
    {
        var renderer = GetComponent<Renderer>();
        var trans = GetComponent<Transform>();

        if (m_mpb == null)
        {
            m_mpb = new MaterialPropertyBlock();
            m_mpb.SetFloat("_ObjectID", m_id);
        }

        var pos = m_use_root_position ? trans.root.position : trans.position;
        var rot = m_use_root_rotation ? trans.root.rotation : trans.rotation;
        var scale = m_use_root_scale ? trans.root.lossyScale : trans.lossyScale;
        if(m_debug_log)
        {
            Debug.Log("pos: " + pos);
            Debug.Log("rot: " + rot);
            Debug.Log("scale: " + scale);
        }
        m_mpb.SetVector("_Position", pos);
        m_mpb.SetVector("_Rotation", new Vector4(rot.x, rot.y, rot.z, rot.w));
        m_mpb.SetVector("_Scale", scale);
        m_mpb.SetFloat("_LocalTime", m_local_time);
        for (int i = 0; i < m_fparams.Count; ++i)
        {
            m_mpb.SetFloat(m_fparams[i].key, m_fparams[i].value);
        }
        renderer.SetPropertyBlock(m_mpb);
    }


    public virtual void LateUpdate()
    {
        if(m_id==0)
        {
            m_id = ++s_idgen;
        }
        m_local_time += Time.deltaTime;

        AssignParams();
    }
}
