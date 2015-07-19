Shader "BooleanRenderer/StencilMask"
{
SubShader
{
    Tags { "RenderType"="Opaque" "Queue"="Geometry-490" }

CGINCLUDE
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
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, v.vertex);
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

depth_out frag_depth(vs_out i)
{
    //float d = ComputeDepth(i.screen_pos);
    float d = i.vertex.z;

    depth_out o;
#if ENABLE_PIERCING
    //float2 t = i.screen_pos.xy / i.screen_pos.w * 0.5 + 0.5;
    float2 t = i.vertex.xy * (_ScreenParams.zw-1.0);
    float target_depth = tex2D(_BackDepth, t);
    o.color = o.depth = target_depth > 0.0 && d > target_depth ? 1.0 : d;
#else
    o.color = o.depth = d;
#endif
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
        Cull Back
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
        Cull Front
        ZTest Greater
        ZWrite On

        CGPROGRAM
        #pragma multi_compile ___ ENABLE_PIERCING

        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag_depth
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
        Cull Back
        ZTest Always
        ZWrite Off
        ColorMask 0

        CGPROGRAM
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }

    // write depth without mask
    Pass {
        Cull Front
        ZTest Greater
        ZWrite On

        CGPROGRAM
        #pragma multi_compile ___ ENABLE_PIERCING

        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag_depth
        ENDCG
    }
}
}
