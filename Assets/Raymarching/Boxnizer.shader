Shader "Raymarcher/Boxnizer" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic("Metallic", Range(0, 1)) = 0.0
    _Position("Position", Vector) = (0, 0, 0, 0)
    _Rotation("Rotation", Vector) = (0, 1, 0, 0)
}

CGINCLUDE
#include "UnityStandardCore.cginc"
#include "distance_functions.cginc"

#define MAX_MARCH_SINGLE_GBUFFER_PASS 5


int g_hdr;
int g_enable_glowline;

float udBox(float3 p, float3 b)
{
    return length(max(abs(p) - b, 0.0));
}

float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}



float3 GetLocalPosition()
{
    return float3(_Object2World[0][3], _Object2World[1][3], _Object2World[2][3]);
}

float3x3 GetLocalRotation()
{
    return float3x3(
        normalize(_Object2World[0].xyz),
        normalize(_Object2World[1].xyz),
        normalize(_Object2World[2].xyz));
}


float3 WorldToLocal(float3 p)
{
    p = mul(transpose(GetLocalRotation()), p - GetLocalPosition());
    return p;
}
float3 LocalToWorld(float3 p)
{
    p = mul(GetLocalRotation(), p + GetLocalPosition());
    return p;
}

float map(float3 p)
{
    p = WorldToLocal(p);

    float grid = 0.26;
    float3 p1 = modc(p, grid) - grid*0.5;
    float d1 = sdBox(p1, 0.11);
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

float2 pattern(float2 p)
{
    p = frac(p);
    float r = 0.123;
    float v = 0.0, g = 0.0;
    r = frac(r * 9184.928);
    float cp, d;
    
    d = p.x;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.y;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.x - 1.0;
    g += pow(clamp(3.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.y - 1.0;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 10000.0);

    const int ITER = 12;
    for(int i = 0; i < ITER; i ++)
    {
        cp = 0.5 + (r - 0.5) * 0.9;
        d = p.x - cp;
        g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 200.0);
        if(d > 0.0) {
            r = frac(r * 4829.013);
            p.x = (p.x - cp) / (1.0 - cp);
            v += 1.0;
        }
        else {
            r = frac(r * 1239.528);
            p.x = p.x / cp;
        }
        p = p.yx;
    }
    v /= float(ITER);
    return float2(g, v);
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
    float max_distance = _ProjectionParams.z - _ProjectionParams.y;
    o_raypos = pos3 + ray_dir * o_total_distance;

    o_num_steps = 0.0;
    o_last_distance = 0.0;
    for(int i=0; i<num_steps; ++i) {
        o_last_distance = map(o_raypos);
        o_total_distance += o_last_distance;
        o_raypos += ray_dir * o_last_distance;
        o_num_steps += 1.0;
        if(o_last_distance < 0.001 || o_total_distance > max_distance) { break; }
    }
    o_total_distance = min(o_total_distance, max_distance);
    //if(o_total_distance > max_distance) { discard; }
}



struct gbuffer_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
    float depth             : SV_Depth;
};


gbuffer_out frag_gbuffer(vs_out v)
{
#if UNITY_UV_STARTS_AT_TOP
    v.screen_pos.y *= -1.0;
#endif
    float time = _Time.y;
    float aspect = _ScreenParams.x / _ScreenParams.y;
    float2 screen_pos = v.screen_pos.xy;
    screen_pos.x *= aspect;
    float3 world_pos = v.world_pos.xyz;

    float num_steps = 1.0;
    float last_distance = 0.0;
    float total_distance = 0;
    float3 ray_pos;
    raymarching(screen_pos, world_pos, MAX_MARCH_SINGLE_GBUFFER_PASS, total_distance, num_steps, last_distance, ray_pos);
    float3 normal = guess_normal(ray_pos);
    normal = lerp(v.normal, normal, saturate(total_distance*1000000));

    float glow = 0.0;
    //if(g_enable_glowline) {
    //    float3 p3 = mul(axis_rotation_matrix33(normalize(float3(_Rotation.xyz)), _Rotation.w), ray_pos);
    //    p3 += _Position.xyz;
    //    p3 *= 2.0;
    //    glow += max((modc(length(p3) - time*3, 15.0) - 12.0)*0.7, 0.0);
    //    float2 p2 = pattern(p3.xz*0.5);
    //    if(p2.x<1.3) { glow = 0.0; }
    //}
    glow += max(1.0-abs(dot(-get_camera_forward(), normal)) - 0.4, 0.0) * 1.0;
    
    float c = total_distance*0.01;
    float4 color = float4( c + float3(0.02, 0.02, 0.025)*num_steps*0.4, 1.0 );
    color.xyz += float3(0.5, 0.5, 0.75)*glow;

    float3 emission = float3(0.7, 0.7, 1.0)*glow*0.6;

    gbuffer_out o;
    o.diffuse = float4(0.75, 0.75, 0.80, 1.0);
    o.spec_smoothness = float4(0.2, 0.2, 0.2, _Glossiness);
    o.normal = float4(normal*0.5+0.5, 1.0);
    //o.emission = g_hdr ? float4(emission, 1.0) : exp2(float4(-emission, 1.0));
    o.emission = float4(emission, 1.0);
    o.depth = compute_depth(mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0)));
#ifndef UNITY_HDR_ON
    o.emission = -exp2(o.emission);
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
ENDCG
    }
    

}
Fallback Off
}
