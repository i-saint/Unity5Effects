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
    public float m_radius = 0.0f;
    public float m_length = 0.0f;
    public Color m_color = Color.white;
    public float m_intensity = 1.0f;

    public float m_speed = 5.0f;
    public float m_appear_time = 0.5f;
    public float m_go_time = 2.0f;
    public float m_fade_time = 0.5f;


    public Shader m_shader;
    public float m_appear = 1.0f;
    public bool m_fired;
    public float m_state_time;

    Material m_material;
    Animator m_animator;


    public virtual void Die()
    {
        Destroy(gameObject);
    }

    public virtual void OnStateCharge()
    {
        m_state_time = 0.0f;
        m_animator.speed = 1.0f / m_appear_time;
    }

    public virtual void OnStateFire()
    {
        m_state_time = 0.0f;
        m_fired = true;
    }

    public virtual void OnStateFade()
    {
        m_state_time = 0.0f;
        m_animator.speed = 1.0f / m_fade_time;
    }


#if UNITY_EDITOR
    public virtual void Reset()
    {
        m_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/Beam/Beam_Transparent.shader");
        GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Utilities/Meshes/IcoSphereI2.asset");
    }
#endif // UNITY_EDITOR

    public virtual void Awake()
    {
        m_animator = GetComponent<Animator>();
    }

    public virtual void Update()
    {
        float dt = Time.deltaTime;

        if (m_material == null)
        {
            m_material = new Material(m_shader);
            GetComponent<MeshRenderer>().sharedMaterial = m_material;
        }

        m_state_time += dt;
        if (m_fired)
        {
            m_length += m_speed * dt;
            if(m_state_time > m_go_time)
            {
                m_animator.CrossFade("Fade", 0.0f);
            }
        }

        var trans = GetComponent<Transform>();
        float s = m_radius * 2.0f * m_appear;
        trans.localScale = new Vector3(s, s, s);
        var forward = trans.forward;
        m_material.SetVector("_BeamDirection", new Vector4(forward.x, forward.y, forward.z, m_length));
        m_material.SetVector("_Color", new Vector4(m_color.r * m_intensity, m_color.g * m_intensity, m_color.b * m_intensity, m_color.a));
    }
}
