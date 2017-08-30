// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

#ifndef IstProceduralModeling_h
#define IstProceduralModeling_h

#include "UnityStandardCore.cginc"
#include "Assets/Ist/Foundation/Shaders/Math.cginc"
#include "Assets/Ist/Foundation/Shaders/Geometry.cginc"
#include "Assets/Ist/Foundation/Shaders/BuiltinVariablesExt.cginc"

#ifndef ENABLE_CUSTUM_VERTEX
struct ia_out
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
    float4 world_pos : TEXCOORD1;
    float3 world_normal: TEXCOORD2;
};


vs_out vert(ia_out I)
{
    vs_out O;
    O.vertex = UnityObjectToClipPos(I.vertex);
    O.screen_pos = ComputeScreenPos(O.vertex);
    O.world_pos = mul(unity_ObjectToWorld, I.vertex);
    O.world_normal = mul(unity_ObjectToWorld, float4(I.normal, 0.0));
    return O;
}
#endif // ENABLE_CUSTUM_VERTEX

struct gbuffer_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
#if ENABLE_DEPTH_OUTPUT
    float depth :
    #if SHADER_TARGET >= 50
        SV_DepthGreaterEqual;
    #else
        SV_Depth;
    #endif
#endif
};

struct raymarch_data
{
    float3 ray_pos;
    float num_steps;
    float total_distance;
    float last_distance;
};


sampler2D _BackDepth;
float4 _Position;
float4 _Rotation;
float4 _Scale;
float4 _OffsetPosition;

float4 _SpecularColor;
float _Smoothness;
float _CutoutDistance;
int _Clipping;


#ifndef _LocalTime
    float _LocalTime;
#endif
#ifndef _ObjectID
    float _ObjectID;
#endif



float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}
float sdSphere(float3 p, float radius)
{
    return length(p) - radius;
}

float sdHex(float2 p, float2 h)
{
    float2 q = abs(p);
    return max(q.x + q.y*0.57735, q.y*1.1547) - h.x;
}

float2 iq_rand(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return frac(sin(p)*43758.5453);
}

float3 nrand3(float2 co)
{
    float3 a = frac(cos(co.x*8.3e-3 + co.y)*float3(1.3e5, 4.7e5, 2.9e5));
    float3 b = frac(sin(co.x*0.3e-3 + co.y)*float3(8.1e5, 1.0e5, 0.1e5));
    float3 c = lerp(a, b, 0.5);
    return c;
}

float soft_min(float a, float b, float r)
{
    float e = max(r - abs(a - b), 0);
    return min(a, b) - e*e*0.25 / r;
}

float soft_max(float a, float b, float r)
{
    float e = max(r - abs(a - b), 0);
    return max(a, b) + e*e*0.25 / r;
}

float3 localize(float3 p)
{
    return mul(unity_WorldToObject, float4(p, 1)).xyz * _Scale.xyz + _OffsetPosition.xyz;
}

#endif // IstProceduralModeling_h
