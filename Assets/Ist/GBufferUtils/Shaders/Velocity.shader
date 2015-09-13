Shader "Ist/GbufferUtils/Velocity"
{


SubShader
{
CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

//float4x4 _PrevViewProj;
float4x4 _PrevObject2World;


struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
    float4 prev_screen_pos : TEXCOORD1;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screen_pos = ComputeScreenPos(o.vertex);

    float4x4 prev_mvp = _PrevObject2World * _PrevViewProj;
    o.prev_screen_pos = ComputeScreenPos(mul(prev_mvp, v.vertex));
    return o;
}

half4 frag(vs_out i) : SV_Target
{
    float2 screen_pos = i.screen_pos.xy / i.screen_pos.w;
    float2 prev_screen_pos = i.prev_screen_pos.xy / i.prev_screen_pos.w;
    float2 vel = screen_pos - prev_screen_pos;
    return half4(vel.xyxy);
}
ENDCG

    // front
    Pass {
        Cull Back
        ZTest Equal
        ZWrite Off

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
