Shader "BooleanRenderer/StencilMask"
{
SubShader
{
    Tags { "RenderType"="Opaque" "Queue"="Geometry-490" }

CGINCLUDE
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
        ZTest Greater
        ZWrite On
        ColorMask 0

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
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
        ZTest Less
        ZWrite Off
        ColorMask 0

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
