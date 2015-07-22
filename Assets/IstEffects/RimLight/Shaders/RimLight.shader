Shader "Hidden/IstImageEffects/RimLight" {
Properties{
    _SrcBlend("", Int) = 1
    _DstBlend("", Int) = 1
}
SubShader{
    Blend[_SrcBlend][_DstBlend]
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/IstEffects/GBufferUtils/Shaders/GBufferUtils.cginc"

float4 _Color;
float4 _Params1;
float4 _Params2;
#define _Intensity      _Params1.x
#define _Threshold      _Params1.y
#define _InvThreshold   _Params1.z
#define _Factor         _Params1.w
#define _EdgeIntensity  _Params2.x
#define _EdgeThreshold  _Params2.y


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
#if UNITY_HDR_ON
    half4
#else
    fixed4
#endif
        color : COLOR0;
};


vs_out vert (ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = v.vertex;
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
}


#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

ps_out frag(vs_out i)
{
    float2 coord = i.screen_pos.xy * 0.5 + 0.5;

    float depth = GetDepth(coord);
    if (depth >= 1.0) { discard; }

    float h = 0.0;
    float3 p = GetPosition(coord).xyz;
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos.xyz);
    float2 pixel_size = _ScreenParams.zw - 1.0;
    float3 n1 = GetNormal(coord).xyz;
    h = pow(max(1.0 - abs(dot(cam_dir, n1) - _Threshold), 0.0) * _InvThreshold, _Factor) * _Intensity;

#if ENABLE_EDGE_HIGHLIGHTING
    float3 n2 = GetNormal(coord + float2(pixel_size.x, 0.0)).xyz;
    float3 n3 = GetNormal(coord + float2(0.0, pixel_size.y)).xyz;

    //if (dot(n1, n2)<_EdgeThreshold || dot(n1, n3)<_EdgeThreshold) {
    //    h += _EdgeIntensity;
    //}

    // equivalent to above code. this if more faster in some cases.
    float t1 = dot(n1, n2) - _EdgeThreshold;
    float t2 = dot(n1, n3) - _EdgeThreshold;
    float t = clamp(min(min(t1, t2), 0.0) * -100000000000.0, 0.0, 1.0);
    h += _EdgeIntensity * t;
#endif
#if ENABLE_SMOOTHNESS_ATTENUAION
    h *= GetSpecular(coord).w;
#endif

    ps_out r;
    r.color = _Color * h;
#ifndef UNITY_HDR_ON
    r.color = exp(-r.color);
#endif
    //r.color = h;
    return r;
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma multi_compile ___ UNITY_HDR_ON
        #pragma multi_compile ___ ENABLE_EDGE_HIGHLIGHTING
        #pragma multi_compile ___ ENABLE_SMOOTHNESS_ATTENUAION
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
