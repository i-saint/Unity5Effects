Shader "Raymarcher/Boxnizer" {
Properties {
    _GridSize("Grid Size", Float) = 0.26
    _BoxSize("Box Size", Float) = 0.22

    _Color("Albedo", Color) = (0.75, 0.75, 0.8, 1.0)
    _SpecularColor("Specular", Color) = (0.2, 0.2, 0.2, 1.0)
    _Smoothness("Smoothness", Range(0, 1)) = 0.7
    _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 1.0)

    _FresnelColor("Fresnel Color", Color) = (0.75, 0.75, 0.8, 1.0)
    _FresnelScale("Fresnel Scale", Float) = 0.3
    _FresnelPow("Fresnel Pow", Float) = 5.0

    _OffsetPosition("OffsetPosition", Vector) = (0, 0, 0, 0)
    _Scale("Scale", Vector) = (1, 1, 1, 0)
}

CGINCLUDE
#include "UnityStandardCore.cginc"
#include "distance_functions.cginc"

#define MAX_MARCH_SINGLE_GBUFFER_PASS 5


float _GridSize;
float _BoxSize;
float4 _FresnelColor;
float _FresnelScale;
float _FresnelPow;

float4 _SpecularColor;
float _Smoothness;
float4 _Position;
float4 _Rotation;
float4 _Scale;
float4 _OffsetPosition;


float udBox(float3 p, float3 b)
{
    return length(max(abs(p) - b, 0.0));
}

float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}



float map(float3 p)
{
    p = mul(_World2Object, float4(p, 1)).xyz * _Scale.xyz + _OffsetPosition.xyz;

    float3 p1 = modc(p, _GridSize) - _GridSize*0.5;
    float d1 = sdBox(p1, _BoxSize*0.5);
    return d1;
}

float3 guess_normal(float3 p)
{
    const float d = 0.001;
    return normalize( float3(
        map(p+float3(  d,0.0,0.0))-map(p+float3( -d,0.0,0.0)),
        map(p+float3(0.0,  d,0.0))-map(p+float3(0.0, -d,0.0)),
        map(p+float3(0.0,0.0,  d))-map(p+float3(0.0,0.0, -d)) ));
}


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
    float3 normal: TEXCOORD2;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.world_pos = mul(_Object2World, v.vertex);
    o.normal = mul(_Object2World, v.normal);
    return o;
}

void raymarching(float2 pos2, float3 pos3, const int num_steps, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
{
    float3 cam_pos      = get_camera_position();
    float3 cam_forward  = get_camera_forward();
    float3 cam_up       = get_camera_up();
    float3 cam_right    = get_camera_right();
    float  cam_focal_len= get_camera_focal_length();
    float3 ray_dir = normalize(cam_right*pos2.x + cam_up*pos2.y + cam_forward*cam_focal_len);
    o_raypos = pos3 + ray_dir * o_total_distance;

    o_num_steps = 0.0;
    o_last_distance = 0.0;
    for(int i=0; i<num_steps; ++i) {
        o_last_distance = map(o_raypos);
        o_total_distance += o_last_distance;
        o_raypos += ray_dir * o_last_distance;
        o_num_steps += 1.0;
        if(o_last_distance < 0.001) { break; }
    }
}



struct gbuffer_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
#if ENABLE_DEPTH_OUTPUT
    float depth             : SV_Depth;
#endif
};


gbuffer_out frag_gbuffer(vs_out v)
{
#if UNITY_UV_STARTS_AT_TOP
    v.screen_pos.y *= -1.0;
#endif
    float2 screen_pos = v.screen_pos.xy;
    screen_pos.x *= _ScreenParams.x / _ScreenParams.y;
    float3 world_pos = v.world_pos.xyz;

    float num_steps = 1.0;
    float last_distance = 0.0;
    float total_distance = 0;
    float3 ray_pos;
    raymarching(screen_pos, world_pos, MAX_MARCH_SINGLE_GBUFFER_PASS, total_distance, num_steps, last_distance, ray_pos);
    float3 normal = guess_normal(ray_pos);
    normal = lerp(v.normal, normal, saturate((total_distance-0.01)*1000000));

    float3 cam_dir = normalize(ray_pos - _WorldSpaceCameraPos);
    float fresnel = saturate(pow(dot(cam_dir, normal) + 1.0, _FresnelPow) * _FresnelScale);

    gbuffer_out o;
    o.diffuse = float4(_Color.rgb, 1.0);
    o.spec_smoothness = float4(_SpecularColor.rgb, _Smoothness);
    o.normal = float4(normal*0.5+0.5, 1.0);
    o.emission = float4(_EmissionColor.rgb + _FresnelColor.rgb * fresnel, 1.0);
#ifndef UNITY_HDR_ON
    o.emission = exp2(-o.emission);
#endif
#if ENABLE_DEPTH_OUTPUT
    o.depth = compute_depth(mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0)));
#endif
    return o;
}


ENDCG

SubShader {
    Tags{ "RenderType" = "Opaque" "DisableBatching" = "True" }
    Cull Off

    Pass {
        Tags { "LightMode" = "Deferred" }
        Stencil {
            Comp Always
            Pass Replace
            Ref 128
        }
CGPROGRAM
#pragma enable_d3d11_debug_symbols
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag_gbuffer
#pragma multi_compile ___ UNITY_HDR_ON
#pragma multi_compile ___ ENABLE_DEPTH_OUTPUT
ENDCG
    }
    

}
Fallback Off
}
