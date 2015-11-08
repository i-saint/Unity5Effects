Shader "BatchRenderer/Transparent" {
Properties {
    [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Int) = 5
    [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Int) = 10

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
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile ___ ENABLE_INSTANCE_BUFFER
#pragma multi_compile ___ ENABLE_INSTANCE_ROTATION
#pragma multi_compile ___ ENABLE_INSTANCE_SCALE
#pragma multi_compile ___ ENABLE_INSTANCE_EMISSION
#pragma multi_compile ___ ENABLE_INSTANCE_COLOR
#pragma multi_compile ___ ENABLE_INSTANCE_UVOFFSET

#define BR_TRANSPARENT
#include "Transparent.cginc"
ENDCG
        }
    }
}
}
