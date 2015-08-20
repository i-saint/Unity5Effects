Shader "BatchRenderer/Transparent" {
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
#pragma target 3.0
#define ENABLE_INSTANCE_ROTATION
#define ENABLE_INSTANCE_SCALE
#define ENABLE_INSTANCE_COLOR
#if SHADER_TARGET > 30
    // on shader model 3.0, this exceeds max interpolator values..
    #define ENABLE_INSTANCE_UVOFFSET
    #define ENABLE_INSTANCE_EMISSION
#endif

#pragma vertex vert
#pragma fragment frag
#pragma multi_compile ___ ENABLE_INSTANCE_BUFFER

#define BR_TRANSPARENT
#include "Transparent.cginc"
ENDCG
        }
    }
}
}
