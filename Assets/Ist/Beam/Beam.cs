using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    [RequireComponent(typeof(Animator))]
    public class Beam : MonoBehaviour
    {
        public enum State
        {
            Charge,
            Fire,
            Fade,
        }

        public float m_radius = 0.0f;
        public float m_length = 0.0f;
        public Color m_color = Color.white;
        public float m_intensity = 1.0f;

        public float m_speed = 5.0f;
        public float m_charge_time = 1.5f;
        public float m_fire_time = 2.0f;
        public float m_fade_time = 0.5f;

        public float m_animation = 1.0f;
        public State m_state = State.Charge;
        public float m_state_time;

        protected Material m_material;


        public virtual void Die()
        {
            Destroy(gameObject);
        }

        public virtual void OnStateCharge()
        {
            m_state = State.Charge;
            m_state_time = 0.0f;
            GetComponent<Animator>().speed = 1.0f / m_charge_time;
        }

        public virtual void OnStateFire()
        {
            m_state = State.Fire;
            m_state_time = 0.0f;
        }

        public virtual void OnStateFade()
        {
            m_state = State.Fade;
            m_state_time = 0.0f;
            GetComponent<Animator>().speed = 1.0f / m_fade_time;
        }

#if UNITY_EDITOR
        public virtual void Reset()
        {
            GetComponent<Renderer>().sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/Beam/Beam_DefaultTransparent.mat");
            GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Utilities/Meshes/IcoSphereI2.asset");
        }
#endif // UNITY_EDITOR


        public virtual void Update()
        {
            float dt = Time.deltaTime;

            m_state_time += dt;
            if (m_state == State.Fire)
            {
                m_length += m_speed * dt;
                if (m_state_time > m_fire_time)
                {
                    GetComponent<Animator>().CrossFade("Fade", 0.0f);
                }
            }
        }

        public virtual void OnWillRenderObject()
        {
            if (m_material == null)
            {
                m_material = new Material(GetComponent<Renderer>().sharedMaterial);
                GetComponent<Renderer>().sharedMaterial = m_material;
            }

            var trans = GetComponent<Transform>();
            var forward = trans.forward;
            var s = m_radius * 2.0f * m_animation;
            trans.localScale = new Vector3(s, s, s);
            m_material.SetVector("_BeamDirection", new Vector4(forward.x, forward.y, forward.z, m_length));
            m_material.SetVector("_Color", new Vector4(m_color.r * m_intensity, m_color.g * m_intensity, m_color.b * m_intensity, m_color.a));
        }
    }
}
