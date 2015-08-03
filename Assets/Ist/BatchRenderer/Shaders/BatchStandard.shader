Shader "BatchRenderer/BatchStandard" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0
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
    #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

#pragma multi_compile ___ USE_INSTANCE_BUFFER

#define BR_STANDARD
#include "Surface.cginc"

ENDCG
} 
FallBack Off
}
