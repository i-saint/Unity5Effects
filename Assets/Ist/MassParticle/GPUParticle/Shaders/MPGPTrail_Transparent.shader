Shader "GPUParticle/Trail Transparent" {

Properties {
    _SrcBlend("SrcBlend", Int) = 5
    _DstBlend("DstBlend", Int) = 1
    _ZWrite("ZWrite", Int) = 0

    _BaseColor ("BaseColor", Color) = (0.15, 0.15, 0.2, 5.0)
    g_width ("Width", Float) = 0.2
    _FadeTime ("FadeTime", Float) = 0.1
}
Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
    Blend [_SrcBlend] [_DstBlend]
    AlphaTest Greater .01
    Cull Off
    Lighting Off
    ZWrite [_ZWrite]

    SubShader {
        Pass {
CGPROGRAM
#pragma target 5.0
#pragma vertex vert
#pragma fragment frag 
#include "MPGPTrail.cginc"
ENDCG
        }
    }
Fallback Off
}
}