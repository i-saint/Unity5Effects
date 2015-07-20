Shader "BatchRenderer/Transparent Add Multiply" {
Properties {
    _MainTex ("Texture", 2D) = "white" {}
    g_base_color ("Base Color", Color) = (1,1,1,1)
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
    Blend SrcAlpha One
    AlphaTest Greater .01
    ColorMask RGB
    Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
    
    SubShader {
        Pass {
CGPROGRAM
#if defined(SHADER_API_OPENGL)
    #pragma glsl
#elif defined(SHADER_API_D3D9)
    #define BR_WITHOUT_INSTANCE_COLOR
    #pragma target 3.0
#endif
#pragma vertex vert
#pragma fragment frag

#pragma multi_compile ___ USE_INSTANCE_BUFFER

#define BR_TRANSPARENT
#include "Transparent.cginc"
ENDCG
        }
    }
}
}
