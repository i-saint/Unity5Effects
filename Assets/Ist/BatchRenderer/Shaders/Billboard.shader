Shader "BatchRenderer/Billboard" {
Properties {
    _SrcBlend("", Int) = 1
    _DstBlend("", Int) = 1

    _MainTex ("Texture", 2D) = "white" {}
    g_base_color ("Base Color", Color) = (1,1,1,1)
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
    Blend[_SrcBlend][_DstBlend]
    AlphaTest Greater .01
    ColorMask RGB
    Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
    
    SubShader {
        Pass {
CGPROGRAM
#if defined(SHADER_API_D3D9)
    #pragma target 3.0
#else
    #pragma target 4.0
#endif
#define ENABLE_INSTANCE_BUFFER
#define ENABLE_INSTANCE_SCALE
#define ENABLE_INSTANCE_ROTATION
#define ENABLE_INSTANCE_UVOFFSET
#define ENABLE_INSTANCE_EMISSION
#if SHADER_TARGET > 40
    // this will exceed max interpolator counts on shader model 3.0
    #define ENABLE_INSTANCE_COLOR
#endif

#pragma vertex vert
#pragma fragment frag

#define BR_BILLBOARD
#include "Billboard.cginc"
ENDCG
        }
    }
}
}
