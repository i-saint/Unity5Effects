Shader "Hidden/IstEffects/CausticsField" {
SubShader {
    Tags { "Queue"="Transparent+100" "RenderType"="Transparent" }
    Blend One One
    ZTest Greater
    ZWrite Off
    Cull Front

CGINCLUDE
#include "Noise.cginc"
#include "Assets/IstEffects/GBufferUtils/Shaders/GBufferUtils.cginc"

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


float3 GetObjectPosition()  { return float3(_Object2World[0][3], _Object2World[1][3], _Object2World[2][3]); }
float3 GetObjectUp()        { return _Object2World[1].xyz; }

ps_out frag(vs_out i)
{
    float2 coord = i.screen_pos.xy / i.screen_pos.w * 0.5 + 0.5;

    float4 pos = GetPosition(coord);
    if(pos.w==0.0) discard;

    float time = _Time.y*_ScrollSpeed;
    float o1 = sea_octave(pos.xzy*1.25*_Scale + float3(1.0, 2.0, -1.5)*time*1.25 + sin(pos.xzy + time*8.3)*0.15, 4.0);
    float o2 = sea_octave(pos.xzy*2.50*_Scale + float3(2.0, -1.0, 1.0)*time*-2.0 - sin(pos.xzy + time*6.3)*0.2, 8.0);
    o1 = (o1*0.5+0.5 -0.2) * 1.2;
    o1 *= (o2*0.5+0.5);
    o1 = pow(o1, _WavePow);

    float attr = 1;
#if ATTENUATION_DIRECTIONAL
    float3 n = GetNormal(coord).xyz;
    float3 opos = GetObjectPosition();
    float3 oup = GetObjectUp();
    float dist = dot(oup, pos) - dot(oup, opos);
    attr = pow(max(1.0 - abs(dist * _Attenuation), 0.0), _AttenuationPow);
    attr *= saturate(1.0 - dot(oup*sign(dist), n));
#elif ATTENUATION_RADIAL
    float3 opos = GetObjectPosition();
    float3 oup = normalize(pos - opos);
    float dist = dot(oup, pos) - dot(oup, opos);
    attr = pow(max(1.0 - abs(dist * _Attenuation), 0.0), _AttenuationPow);
    attr *= saturate(1.0 - dot(oup*sign(dist), n));
#endif


    ps_out r;
    r.color = _Color * (o1 * attr * _Intensity);
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
