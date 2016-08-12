// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Ist/StencilShadows/Stencil"
{
Properties {
    _OcculusionStrength("Occulusion Strength", Float) = 0.5
}

SubShader
{
CGINCLUDE
#include "UnityCG.cginc"

struct ia_out
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
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


float _OcculusionStrength;
float4 _StencilParams1;
#define _Center     _StencilParams1.xyz
#define _Range      _StencilParams1.w


void distance_point_line(float3 ppos, float3 pos1, float3 pos2,
    out float3 nearest, out float3 direction, out float dist)
{
    float3 d = pos2 - pos1;
    float t = dot(ppos - pos1, pos2 - pos1) / dot(d, d);
    nearest = pos1 + (pos2 - pos1) * clamp(t, 0.0, 1.0);
    float3 diff = ppos - nearest;
    dist = length(diff);
    direction = normalize(diff);
}


void Project(inout float3 pos, float3 n)
{
    float3 dir = 0.0;
    float dist = 0.0;

#if PROJECTION_POINT
    dir = normalize(pos - _Center);
    dist = _Range;
#if ENABLE_INVERSE
    dir *= -1.0;
    dist = length(pos - _Center);
#endif

    // todo
#elif PROJECTION_LINE
    dir = normalize(pos - _Center);
    dist = _Range;
#if ENABLE_INVERSE
    dir *= -1.0;
    dist = length(pos - _Center);
#endif
#endif

    float proj = clamp(dot(-dir.xyz, n.xyz)*10000, 0.0, 1.0);
    pos += dir * (dist * proj);
}


vs_out vert(ia_out v)
{
    float3 pos = mul(unity_ObjectToWorld, v.vertex).xyz;
    float3 n = normalize(mul(unity_ObjectToWorld, float4(v.normal.xyz, 0.0)).xyz);
    Project(pos, n);

    vs_out o;
    o.vertex = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

ps_out frag1(vs_out i)
{
    ps_out r;
    r.color = _OcculusionStrength;
    return r;
}
ps_out frag2(vs_out i)
{
    ps_out r;
    r.color = -_OcculusionStrength;
    return r;
}
ENDCG

    // front
    Pass {
        Cull Back
        ZTest Less
        ZWrite Off
        Blend One One

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag1
        #pragma multi_compile PROJECTION_POINT PROJECTION_LINE
        #pragma multi_compile ___ ENABLE_INVERSE
        ENDCG
    }

    // back
    Pass {
        Cull Front
        ZTest Less
        ZWrite Off
        Blend One One

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag2
        #pragma multi_compile PROJECTION_POINT PROJECTION_LINE
        #pragma multi_compile ___ ENABLE_INVERSE
        ENDCG
    }
}
}
