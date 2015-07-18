Shader "BooleanRenderer/StencilMask"
{
SubShader
{
    Tags { "RenderType"="Opaque" "Queue"="Geometry-490" }

CGINCLUDE
sampler2D _BackDepth;
sampler2D _PrevDepth;

struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    return o;
}

half4 frag(vs_out i) : SV_Target
{
    return 0.0;
}

struct depth_out
{
    half4 color : SV_Target;
    float depth : SV_Depth;
};

depth_out frag_depth(vs_out i)
{
    float frag_depth = i.vertex.z;

    depth_out o;
    o.color = 0.0;

#if ENABLE_PIERCING
    float2 t = i.vertex.xy * (_ScreenParams.zw-1.0);
    float target_depth = tex2D(_BackDepth, t);
    o.depth = target_depth > 0.0 && frag_depth > target_depth ? 1.0 : frag_depth;
#else
    o.depth = frag_depth;
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
        ZTest GEqual
        ZWrite On
        ColorMask 0

        CGPROGRAM
        #pragma multi_compile ___ ENABLE_PIERCING

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
        ZTest Equal
        ZWrite Off
        ColorMask 0

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }

    // write depth without mask
    Pass {
        Cull Front
        ZTest Greater
        ZWrite On
        ColorMask 0

        CGPROGRAM
        #pragma multi_compile ___ ENABLE_PIERCING

        #pragma vertex vert
        #pragma fragment frag_depth
        ENDCG
    }
}
}
