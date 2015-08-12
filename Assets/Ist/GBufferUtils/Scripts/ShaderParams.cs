using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

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
    public List<StringBoolPair> m_keyworkds = new List<StringBoolPair>();
    public List<StringFloatPair> m_fparams_local = new List<StringFloatPair>();
    public List<StringFloatPair> m_fparams_shared = new List<StringFloatPair>();

    uint m_id;
    Material m_material;
    MaterialPropertyBlock m_mpb;

    public void ResetMaterial()
    {
        m_mpb = null;
        m_material = null;
    }

    public void AssignParams()
    {
        var renderer = GetComponent<Renderer>();
        var trans = GetComponent<Transform>();
        if (m_material == null)
        {
            m_material = m_share_material ? renderer.sharedMaterial : new Material(renderer.sharedMaterial);
            renderer.sharedMaterial = m_material;
            for (int i = 0; i < m_keyworkds.Count; ++i)
            {
                if(m_keyworkds[i].value)
                {
                    m_material.EnableKeyword(m_keyworkds[i].key);
                }
                else
                {
                    m_material.DisableKeyword(m_keyworkds[i].key);
                }
            }
        }
        if (m_mpb == null)
        {
            m_mpb = new MaterialPropertyBlock();
            m_mpb.SetFloat("_ObjectID", m_id);
        }

        for (int i = 0; i < m_fparams_shared.Count; ++i)
        {
            m_material.SetFloat(m_fparams_shared[i].key, m_fparams_shared[i].value);
        }

        var rot = trans.rotation;
        m_mpb.SetVector("_Position", trans.position);
        m_mpb.SetVector("_Rotation", new Vector4(rot.x, rot.y, rot.z, rot.w));
        m_mpb.SetVector("_Scale", trans.localScale);
        m_mpb.SetFloat("_LocalTime", m_local_time);
        for (int i = 0; i < m_fparams_local.Count; ++i)
        {
            m_mpb.SetFloat(m_fparams_local[i].key, m_fparams_local[i].value);
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
