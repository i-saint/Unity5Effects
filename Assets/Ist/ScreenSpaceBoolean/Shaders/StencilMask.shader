Shader "Ist/Boolean/StencilMask"
{
SubShader
{
    Tags { "RenderType"="Opaque" "Queue"="Geometry-490" }

CGINCLUDE
#include "UnityCG.cginc"

sampler2D _BackDepth;

float ComputeDepth(float4 clippos)
{
#if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
    return (clippos.z / clippos.w) * 0.5 + 0.5;
#else
    return clippos.z / clippos.w;
#endif
}


struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
};



vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

half4 frag(vs_out i) : SV_Target
{
    return ComputeDepth(i.screen_pos);
}


struct depth_out
{
    half4 color : SV_Target;
    float depth : SV_Depth;
};

depth_out frag_pierce(vs_out i)
{
    float d = ComputeDepth(i.screen_pos);

    depth_out o;
    float2 t = i.screen_pos.xy / i.screen_pos.w;
    float target_depth = tex2D(_BackDepth, t);
    if (d <= target_depth) { discard; }
    o.color = o.depth = 1.0;
    return o;
}
ENDCG

    // write stencil
    Pass {
        Stencil {
            Ref 1
            ReadMask 1
            WriteMask 1
            Comp Always
            Pass Replace
        }
        Cull Front
        ZTest Less
        ZWrite Off
        ColorMask 0

        CGPROGRAM
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }

    // write depth with mask
    Pass {
        Stencil {
            Ref 1
            ReadMask 1
            WriteMask 1
            Comp Equal
        }
        Cull Back
        ZTest Greater
        ZWrite On

        CGPROGRAM
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
    
    // clar depth if pierced
    Pass {
        Stencil {
            Ref 1
            ReadMask 1
            WriteMask 1
            Comp Equal
        }
        Cull Back
        ZTest Greater
        ZWrite On

        CGPROGRAM
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag_pierce
        ENDCG
    }

    // clear stencil
    Pass {
        Stencil {
            Ref 0
            ReadMask 1
            WriteMask 1
            Comp Always
            Pass Replace
        }
        Cull Front
        ZTest Always
        ZWrite Off
        ColorMask 0

        CGPROGRAM
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
