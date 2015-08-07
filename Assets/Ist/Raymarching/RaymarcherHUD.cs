using UnityEngine;
using System.Collections;

using UnityStandardAssets.ImageEffects;

[RequireComponent(typeof(Raymarcher))]
[ExecuteInEditMode]
public class RaymarcherHUD : MonoBehaviour
{
    public bool m_show_hud;


    void Update()
    {
        if(Input.GetKeyDown(KeyCode.Tab))
        {
            m_show_hud = !m_show_hud;
        }
    }

    void OnGUI()
    {
        if (!m_show_hud) return;

        Raymarcher rm = GetComponent<Raymarcher>();
        Camera cam = GetComponent<Camera>();

        rm.enabled = GUI.Toggle(new Rect(20, 20, 200, 20), rm.enabled, "enable raymarcher");
        rm.m_enable_adaptive = GUI.Toggle(new Rect(20, 50, 200, 20), rm.m_enable_adaptive, "adaptive subsampling");
        if (rm.m_enable_adaptive)
        {
            rm.m_enable_temporal = GUI.Toggle(new Rect(30, 80, 200, 20), rm.m_enable_temporal, "temporal marching");
        }


        rm.m_enable_glowline = GUI.Toggle(new Rect(20, 120, 200, 20), rm.m_enable_glowline, "glowline");
        {
            var ssao = cam.GetComponent<ScreenSpaceAmbientOcclusion>();
            if(ssao!=null) {
                ssao.enabled = GUI.Toggle(new Rect(20, 150, 200, 20), ssao.enabled, "SSAO");
            }
        }

        if (GUI.Button(new Rect(30, 180, 120, 20), "next scene"))
        {
            rm.m_scene = (rm.m_scene + 1) % 3;
        }

        GUI.Label(new Rect(20, 210, 210, 20), "tab: show / hide UI");
    }
}
