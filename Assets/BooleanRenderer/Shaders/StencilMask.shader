Shader "BooleanRenderer/StencilMask"
{
SubShader
{
CGINCLUDE
struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
};

struct ps_out
{
    float4 color : SV_Target;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    return o;
}

ps_out frag(vs_out i)
{
    ps_out o;
    o.color = 0.0;
    return o;
}
ENDCG

    Pass {
        Stencil {
            Ref 1
            Comp Always
            Pass Replace
        }
        ColorMask 0
        ZWrite Off
        ZTest Less
        Cull Back

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
    Pass {
        Stencil {
            Ref 0
            Comp Always
            Pass Replace
        }
        ColorMask 0
        ZWrite Off
        ZTest Always
        Cull Front

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
