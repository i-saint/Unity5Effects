Shader "Hidden/IstNormalLighting" {
Properties {
}
SubShader {
    Tags { "RenderType"="Opaque" }
    Blend One One
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/GBufferUtils/Shaders/GBufferUtils.cginc"

float4 _BaseColor;
float _Intensity;
float _Threshold;
float _Edge;


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
    float4 color : COLOR0;
};


vs_out vert (ia_out v)
{
    vs_out o;
    o.vertex = v.vertex;
    o.screen_pos = v.vertex;
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
}

ps_out frag(vs_out i)
{
    float2 coord = i.screen_pos.xy / i.screen_pos.w * 0.5 + 0.5;

    float3 n1 = GetNormal(coord).xyz;
    if(dot(n1, 1.0)==0.0) { discard; }

    float glow = 0.0;
    float3 p = GetPosition(coord).xyz;
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos.xyz);
    float tw = _ScreenParams.z - 1.0;
    float th = _ScreenParams.w - 1.0;
    float3 n2 = GetNormal(coord+float2(tw, 0.0)).xyz;
    float3 n3 = GetNormal(coord+float2(0.0, th)).xyz;
    glow = max(1.0-abs(dot(cam_dir, n1)-_Threshold), 0.0)*_Intensity;
    if(dot(n1, n2)<0.8 || dot(n1, n3)<0.8) {
        glow += _Edge;
    }

    ps_out r;
    r.color = _BaseColor * glow * GetAlbedo(coord).w;
    return r;
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
