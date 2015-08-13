using UnityEngine;
using System.Collections;

public class RandomRotation : MonoBehaviour
{
    public float m_speed1;
    public float m_speed2;
    public float m_angle;
    public Vector3 m_axis;
    Transform m_trans;

    void Awake()
    {
        m_trans = GetComponent<Transform>();
        m_axis = new Vector3(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f)).normalized;
        m_speed1 = Random.Range(0.5f, 1.0f) * m_speed1;
        m_speed2 = Random.Range(0.25f, 1.0f) * m_speed2 * Mathf.Sign(Random.Range(-1.0f, 1.0f));
        m_angle = Random.Range(0.0f, 360.0f);
    }

    void Update()
    {
        m_angle += m_speed1 * Time.deltaTime;
        m_trans.rotation = Quaternion.AngleAxis(m_angle, m_axis);
        m_trans.RotateAround(Vector3.zero, Vector3.up, m_speed2);
    }
}
