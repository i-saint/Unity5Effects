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

    public bool m_share_material = true;
    public float m_local_time;
    public List<StringFloatPair> m_fparams = new List<StringFloatPair>();

    uint m_id;
    MaterialPropertyBlock m_mpb;

    public void AssignParams()
    {
        var renderer = GetComponent<Renderer>();
        var trans = GetComponent<Transform>();
        var material = renderer.sharedMaterial;

        if (m_mpb == null)
        {
            m_mpb = new MaterialPropertyBlock();
            m_mpb.SetFloat("_ObjectID", m_id);
        }

        var rot = trans.rotation;
        m_mpb.SetVector("_Position", trans.position);
        m_mpb.SetVector("_Rotation", new Vector4(rot.x, rot.y, rot.z, rot.w));
        m_mpb.SetVector("_Scale", trans.localScale);
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
