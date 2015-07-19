using UnityEngine;
using System.Collections;

public class TekitouAnimation : MonoBehaviour
{
    public Transform[] m_updown;
    public float m_speed = 1.0f;
    public float max_y = 2.0f;


    void Update()
    {
        float dt = Time.deltaTime;
        for (int i = 0; i < m_updown.Length; ++i )
        {
            var t = m_updown[i];
            Vector3 pos = t.position;
            pos.y += m_speed * dt;
            if (pos.y > max_y) { pos.y -= max_y+0.5f; }
            t.position = pos;
        }
    }
}
