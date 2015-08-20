Shader "BatchRenderer/Standard" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0
}
SubShader {
    Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }

CGPROGRAM
#pragma target 3.0
#define ENABLE_INSTANCE_SCALE
#define ENABLE_INSTANCE_ROTATION
#define ENABLE_INSTANCE_EMISSION
#if SHADER_TARGET > 30
    // on shader model 3.0, this exceeds max interpolator values..
    #define ENABLE_INSTANCE_UVOFFSET
    #define ENABLE_INSTANCE_COLOR
#endif

#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
#pragma multi_compile ___ ENABLE_INSTANCE_BUFFER

#define BR_STANDARD
#include "Surface.cginc"
ENDCG
}

FallBack Off
}
