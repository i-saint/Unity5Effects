using UnityEngine;
using System.Collections;

public class TestProceduralModelingScene : MonoBehaviour
{
    public GameObject m_floater;
    public int m_num_floaters = 30;

    void Awake()
    {
        for(int i=0; i< m_num_floaters; ++i)
        {
            GameObject obj = Instantiate(m_floater);
            var t = obj.GetComponent<Transform>();
            var v = new Vector3(Random.Range(-1.0f, 1.0f), Random.Range(-0.2f, 0.3f), Random.Range(-1.0f, 1.0f)).normalized;
            t.position = v * Random.Range(5.0f, 12.0f);
        }
    }
}
