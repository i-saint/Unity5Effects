Shader "BooleanRenderer/BackDepth"
{

SubShader
{
CGINCLUDE

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

struct ps_out
{
    float4 color : SV_Target;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, v.vertex);
    return o;
}

ps_out frag(vs_out i)
{
    ps_out r;
    r.color = ComputeDepth(i.screen_pos);
    return r;
}
ENDCG

    Pass {
        Tags { "RenderType"="Opaque" }
        ZTest Greater
        ZWrite On
        Cull Front

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
