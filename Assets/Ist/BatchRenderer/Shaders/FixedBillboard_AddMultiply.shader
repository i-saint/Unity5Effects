Shader "BatchRenderer/FixedBillboard Add Multiply" {
Properties {
    _MainTex ("Texture", 2D) = "white" {}
    g_base_color ("Base Color", Color) = (1,1,1,1)
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
    Blend One OneMinusSrcAlpha
    ColorMask RGB
    Cull Off Lighting Off ZWrite Off ZTest Always Fog { Color (0,0,0,1) }

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

#define BR_FIXED_BILLBOARD
#include "Billboard.cginc"
ENDCG
        }
    }
}
}
