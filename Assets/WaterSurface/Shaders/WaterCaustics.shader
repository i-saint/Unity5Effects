Shader "WaterSurface/Caustics" {
Properties {
}
SubShader {
    Tags { "Queue"="Transparent+100" "RenderType"="Opaque" }
    Blend One One
    ZTest Greater
    ZWrite Off
    Cull Front

CGINCLUDE
#include "Compat.cginc"
#include "Noise.cginc"
#include "Assets/GBufferUtils/Shaders/GBufferUtils.cginc"

float g_intensity;
float g_speed;

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
    float4 spos = mul(UNITY_MATRIX_MVP, v.vertex);
    vs_out o;
    o.vertex = spos;
    o.screen_pos = spos;
    return o;
}

ps_out frag(vs_out i)
{
    float2 coord = (i.screen_pos.xy / i.screen_pos.w + 1.0) * 0.5;
    #if UNITY_UV_STARTS_AT_TOP
        coord.y = 1.0-coord.y;
    #endif

    float4 pos = GetPosition(coord);
    if(pos.w==0.0) discard;

    float time = _Time.y*g_speed;
    float o1 = sea_octave(pos.xzy*1.25 + float3(1.0,2.0,-1.5)*time*1.25 + sin(pos.xzy+time*8.3)*0.15, 4.0);
    float o2 = sea_octave(pos.xzy*2.50 + float3(2.0,-1.0,1.0)*time*-2.0 - sin(pos.xzy+time*6.3)*0.2, 8.0);
    o1 = (o1*0.5+0.5 -0.2) * 1.2;
    o1 *= (o2*0.5+0.5);
    o1 = pow(o1, 10.0);

    float3 n = GetNormal(coord).xyz;
    float s = 1.0;
    if(pos.y > 0.0) {
        s = dot(n, float3(0.0, -1.0, 0.0))*0.5+0.5;
        s = max(s-0.1-pos.y*0.1, 0.0)*1.25;
    }

    ps_out r;
    r.color = o1*float4(0.5, 0.5, 1.5, 1.0) * 0.7 * s * g_intensity;
    return r;
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 3.0
        ENDCG
    }
}
}
