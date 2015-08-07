Shader "GPUParticle/Transparent" {

Properties {
    _SrcBlend("SrcBlend", Int) = 1
    _DstBlend("DstBlend", Int) = 1

    _MainTex ("Albedo", 2D) = "white" {}
    _Color("Albedo Color", Color) = (0.8, 0.8, 0.8, 1.0)
    _Emission("Emission Color", Color) = (0, 0, 0, 0)
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0

    _HeatThreshold("Heat Threshold", Float) = 2.0
    _HeatIntensity("Heat Intensity", Float) = 1.0
    _HeatColor("Heat Color", Color) = (0.25, 0.05, 0.025, 0.0)

    g_size ("Particle Size", Float) = 0.2
    g_fade_time ("Fade Time", Float) = 0.3
    g_spin ("Spin", Float) = 0.0
}

SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    Blend[_SrcBlend][_DstBlend]

    Pass {
CGPROGRAM
#pragma target 5.0
#pragma vertex vert
#pragma fragment frag 

#define MPGP_TRANSPARENT
#include "MPGPSurface.cginc"
ENDCG
    }
}


FallBack Off
}
