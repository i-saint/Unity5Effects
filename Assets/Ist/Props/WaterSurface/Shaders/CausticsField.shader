// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/Ist/CausticsField" {
SubShader {
    Tags { "Queue"="Transparent+100" "RenderType"="Transparent" }
    Blend One One
    ZTest Greater
    ZWrite Off
    Cull Front

CGINCLUDE
#include "Noise.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

float4 _Color;
float4 _Params1;
float4 _Params2;

#define _ScrollSpeed    _Params1.x
#define _Scale          _Params1.y
#define _Intensity      _Params1.z
#define _WavePow        _Params1.w
#define _Attenuation    _Params2.x
#define _AttenuationPow _Params2.y


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
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
}


float3 GetObjectPosition()  { return float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]); }
float3 GetObjectUp()        { return normalize(unity_ObjectToWorld[1].xyz); }

ps_out frag(vs_out i)
{
    float2 spos = i.screen_pos.xy / i.screen_pos.w;
    float2 uv = spos * 0.5 + 0.5;

    float depth = GetDepth(uv);
    if(depth ==1.0) discard;
    float3 pos = GetPosition(spos, depth);

    float time = _Time.y*_ScrollSpeed;
    float o1 = sea_octave(pos.xzy*1.25*_Scale + float3(1.0, 2.0, -1.5)*time*1.25 + sin(pos.xzy + time*8.3)*0.15, 4.0);
    float o2 = sea_octave(pos.xzy*2.50*_Scale + float3(2.0, -1.0, 1.0)*time*-2.0 - sin(pos.xzy + time*6.3)*0.2, 8.0);
    o1 = (o1*0.5+0.5 -0.2) * 1.2;
    o1 *= (o2*0.5+0.5);
    o1 = pow(o1, _WavePow);

    float attr1 = 1;
    float attr2 = 1;
#if ATTENUATION_DIRECTIONAL
    float3 n = GetNormal(uv).xyz;
    float3 opos = GetObjectPosition();
    float3 oup = GetObjectUp();
    float dist = dot(oup, pos.xyz) - dot(oup, opos.xyz);
    float sign = clamp(dist * 10000, -1, 1);
    attr1 = pow(saturate(1.0 - abs(dist * _Attenuation)), _AttenuationPow);
    attr2 = max(-dot(oup*sign, n), 0.0);
#elif ATTENUATION_RADIAL
    float3 n = GetNormal(uv).xyz;
    float3 opos = GetObjectPosition();
    float3 odir = normalize(pos - opos);
    float dist = length(pos - opos);
    attr1 = pow(saturate(1.0 - (dist * _Attenuation)), _AttenuationPow);
    attr2 = max(-dot(odir, n), 0.0);
#endif

    ps_out r;
    r.color = _Color * (o1 * attr1 * attr2 * _Intensity);
    return r;
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma multi_compile ATTENUATION_NONE ATTENUATION_DIRECTIONAL ATTENUATION_RADIAL
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 3.0
        ENDCG
    }
}
}
