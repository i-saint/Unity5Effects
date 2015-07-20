Shader "BatchRenderer/Lambert Detailed" {
Properties {
    g_base_color ("Base Color", Color) = (1,1,1,1)
    g_base_emission ("Emission", Color) = (0,0,0,0)
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _NormalMap ("Normalmap", 2D) = "bump" {}
    _EmissionMap ("Emissionmap", 2D) = "black" {}
    _SpecularMap ("Specularmap", 2D) = "white" {}
    _GrossMap ("Grossmap", 2D) = "white" {}
}
SubShader {
    Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }

CGPROGRAM
#if defined(SHADER_API_OPENGL)
    #pragma glsl
#elif defined(SHADER_API_D3D9)
    #define BR_WITHOUT_INSTANCE_COLOR
    #define BR_WITHOUT_INSTANCE_EMISSION
    #pragma target 3.0
#endif
#pragma surface surf Lambert vertex:vert addshadow

#pragma multi_compile ___ USE_INSTANCE_BUFFER

#define BR_SURFACE_DETAILED
#include "Surface.cginc"
ENDCG
}

Fallback Off
}
