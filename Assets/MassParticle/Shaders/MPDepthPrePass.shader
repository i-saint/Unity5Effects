Shader "MassParticle/DepthPrePass" {

Properties {
    g_size ("Particle Size", Float) = 0.2
    g_fade_time ("Fade Time", Float) = 0.3
    g_spin ("Spin", Float) = 0.0
}

SubShader {
    Tags { "RenderType"="Opaque" "Queue"="Geometry-1" }
    ZWrite On ZTest LEqual
    ColorMask 0

CGPROGRAM
#pragma surface surf Standard vertex:vert
#pragma target 3.0

#define MP_STANDARD
#include "MPSurface.cginc"
ENDCG
}
FallBack Off

}
