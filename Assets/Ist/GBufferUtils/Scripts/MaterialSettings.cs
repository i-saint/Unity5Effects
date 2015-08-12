using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[AddComponentMenu("Ist/Material Settings")]
[ExecuteInEditMode]
public class MaterialSettings : MonoBehaviour
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

    [System.Serializable]
    public class MaterialSetting
    {
        public Material material;
        public List<StringBoolPair> keyworkds = new List<StringBoolPair>();
        public List<StringFloatPair> fparams = new List<StringFloatPair>();
    }

    public bool m_assign_on_update;
    public List<MaterialSetting> m_settings = new List<MaterialSetting>();


    public void AssignParams()
    {
        for (int i = 0; i < m_settings.Count; ++i)
        {
            AssignParams(m_settings[i]);
        }
    }

    public MaterialSetting FindSetting(string material_name)
    {
        return m_settings.Find((a) => { return a.material.name == material_name; });
    }

    void AssignParams(MaterialSetting setting)
    {
        var mat = setting.material;
        var keywords = setting.keyworkds;
        var fparams = setting.fparams;

        for (int i = 0; i < keywords.Count; ++i)
        {
            if (keywords[i].value)
            {
                mat.EnableKeyword(keywords[i].key);
            }
            else
            {
                mat.DisableKeyword(keywords[i].key);
                
            }
            //Debug.Log(mat.name + " " + keywords[i].key + " " + mat.IsKeywordEnabled(keywords[i].key));
        }

        for (int i = 0; i < fparams.Count; ++i)
        {
            mat.SetFloat(fparams[i].key, fparams[i].value);
        }
    }


    public virtual void Awake()
    {
        AssignParams();
    }

    public virtual void LateUpdate()
    {
        if(m_assign_on_update)
        {
            AssignParams();
        }
    }
}
