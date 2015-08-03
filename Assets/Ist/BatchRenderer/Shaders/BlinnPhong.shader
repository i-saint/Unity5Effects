Shader "BatchRenderer/BlinnPhong" {
Properties {
    g_base_color ("Base Color", Color) = (1,1,1,1)
    g_base_emission ("Emission", Color) = (0,0,0,0)
    _MainTex ("Base (RGB)", 2D) = "white" {}
}
SubShader {
    Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }

CGPROGRAM
#if defined(SHADER_API_OPENGL)
    #pragma glsl
#elif defined(SHADER_API_D3D9)
    #pragma target 3.0
    #define BR_WITHOUT_INSTANCE_COLOR
    #define BR_WITHOUT_INSTANCE_EMISSION
#else
    #pragma target 4.0
#endif
#pragma surface surf BlinnPhong vertex:vert addshadow

#pragma multi_compile ___ USE_INSTANCE_BUFFER

#define BR_SURFACE
#include "Surface.cginc"
ENDCG
}

Fallback Off
}
