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

#define _ScrollSpeed    _Params1.x
#define _Scale          _Params1.y
#define _Intensity      _Params1.z
#define _Pow            _Params1.w


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
    o1 = pow(o1, _Pow);

    float3 n = GetNormal(coord).xyz;
    float s = 1.0;
    //if(pos.y > 0.0) {
    //    s = dot(n, float3(0.0, -1.0, 0.0))*0.5+0.5;
    //    s = max(s-0.1-pos.y*0.1, 0.0)*1.25;
    //}

    ps_out r;
    r.color = _Color * (o1 * _Intensity * s);
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
