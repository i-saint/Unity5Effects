Shader "BatchRenderer/Standard" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic("Metallic", Range(0,1)) = 0.0
    _Emission("Emission", Color) = (0,0,0,0)
}
SubShader {
    Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }

CGPROGRAM
#pragma target 3.0
#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
#pragma multi_compile ___ ENABLE_INSTANCE_BUFFER
#pragma multi_compile ___ ENABLE_INSTANCE_ROTATION
#pragma multi_compile ___ ENABLE_INSTANCE_SCALE
#pragma multi_compile ___ ENABLE_INSTANCE_EMISSION
#pragma multi_compile ___ ENABLE_INSTANCE_UVOFFSET
#pragma multi_compile ___ ENABLE_INSTANCE_COLOR


#define BR_STANDARD
#include "Surface.cginc"
ENDCG
}

FallBack Off
}
