using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class Beam : MonoBehaviour
{
    public float m_length = 0.0f;
    public Vector3 m_color;
    public Shader m_shader;

    Material m_material;


    public void Die() { Destroy(gameObject); }


#if UNITY_EDITOR
    void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/Beam/Beam_Transparent.shader");
        GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Utilities/Meshes/IcoSphereI2.asset");
    }
#endif // UNITY_EDITOR

    void Update()
    {
        if (m_material == null)
        {
            m_material = new Material(m_shader);
            GetComponent<MeshRenderer>().sharedMaterial = m_material;
        }

        var forward = GetComponent<Transform>().forward;
        m_material.SetVector("_BeamDirection", new Vector4(forward.x, forward.y, forward.z, m_length));
        m_material.SetVector("_Color", m_color);
    }
}
