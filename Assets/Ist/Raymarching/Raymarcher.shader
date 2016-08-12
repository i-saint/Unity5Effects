// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Raymarcher/RayMarcher" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic("Metallic", Range(0, 1)) = 0.0
    _Position("Position", Vector) = (0, 0, 0, 0)
    _Rotation("Rotation", Vector) = (0, 1, 0, 0)
    _Scale("Scale", Vector) = (1, 1, 1, 0)

    _Scene("Scene", Float) = 0

    [Toggle(ENABLE_SCREENSPACE)] _EnableScreenSpace("ScreenSpace", Float) = 0
    [Toggle(ENABLE_ADAPTIVE)] _EnableAdaptive("Adaptive", Float) = 0
    [Toggle(ENABLE_TEMPORAL)] _EnableTemporal("Temporal", Float) = 0
    [Toggle(ENABLE_PATTERN)] _EnablePattern("Pattern", Float) = 0
}

CGINCLUDE
#include "UnityStandardCore.cginc"
#include "distance_functions.cginc"

#define MAX_MARCH_OPASS 100
#define MAX_MARCH_QPASS 40
#define MAX_MARCH_HPASS 20
#define MAX_MARCH_APASS 5
#define MAX_MARCH_SINGLE_GBUFFER_PASS 100


int _Scene;
float3 _Position;
float4 _Rotation;
float3 _Scale;

float3 localize(float3 p)
{
#if ENABLE_SCREENSPACE
    p = mul(RotateAxis33(normalize(float3(_Rotation.xyz)), _Rotation.w), p);
    p -= _Position.xyz;
#else
    p = mul(unity_WorldToObject, float4(p, 1)).xyz * _Scale.xyz;
#endif
    return p;
}

float map(float3 p)
{
    p = localize(p);

    if(_Scene==0) {
        return pseudo_kleinian( (p+float3(0.0, -0.5, 0.0)).xzy );
    }
    else if (_Scene==1) {
        return tglad_formula(p);
    }
    else {
        return pseudo_knightyan( (p+float3(0.0, -0.5, 0.0)).xzy );
    }

    //return length(p)-1.0;
    //return kaleidoscopic_IFS(p);
    //return pseudo_knightyan( (p+float3(0.0, -0.5, 0.0)).xzy );
    //return hartverdrahtet( (p+float3(0.0, -0.5, 0.0)).xzy );
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
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 spos : TEXCOORD0;
};


vs_out vert(ia_out I)
{
    vs_out O;
#if ENABLE_SCREENSPACE
    O.vertex = I.vertex;
#else
    O.vertex = mul(UNITY_MATRIX_MVP, I.vertex);
#endif
    O.spos = O.vertex;
    return O;
}

vs_out vert_dummy(ia_out I)
{
    vs_out O;
    O.vertex = O.spos = float4(0.0, 0.0, 0.0, 1.0);
    return O;
}


void raymarching(float2 pos, const int num_steps, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
{
    float3 cam_pos      = GetCameraPosition();
    float3 cam_forward  = GetCameraForward();
    float3 cam_up       = GetCameraUp();
    float3 cam_right    = GetCameraRight();
    float  cam_focal_len= GetCameraFocalLength();

    float3 ray_dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward*cam_focal_len);
    float max_distance = _ProjectionParams.z - _ProjectionParams.y;
    o_raypos = cam_pos + ray_dir * o_total_distance;

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


gbuffer_out frag_gbuffer(vs_out I)
{
    I.spos.xy /= I.spos.w;
#if UNITY_UV_STARTS_AT_TOP
    I.spos.y *= -1.0;
#endif
    float time = _Time.y;
    float2 coord = I.spos.xy;
    coord.x *= GetAspectRatio();

    float num_steps = 1.0;
    float last_distance = 0.0;
    float total_distance = _ProjectionParams.y;
    float3 ray_pos;
    float3 normal;
#if ENABLE_ADAPTIVE
    {
        float3 cam_pos      = GetCameraPosition();
        float3 cam_forward  = GetCameraForward();
        float3 cam_up       = GetCameraUp();
        float3 cam_right    = GetCameraRight();
        float  cam_focal_len= GetCameraFocalLength();
        float3 ray_dir = normalize(cam_right*coord.x + cam_up*coord.y + cam_forward*cam_focal_len);

        total_distance = tex2D(g_depth, I.spos.xy*0.5+0.5).x;
        ray_pos = cam_pos + ray_dir * total_distance;
        normal = guess_normal(ray_pos);
        }
#else // ENABLE_ADAPTIVE
    {
        raymarching(coord, MAX_MARCH_SINGLE_GBUFFER_PASS, total_distance, num_steps, last_distance, ray_pos);
        normal = guess_normal(ray_pos);
    }
#endif // ENABLE_ADAPTIVE

    float glow = 0.0;
#if ENABLE_PATTERN
    {
        float3 p3 = localize(ray_pos);
        p3 *= 2.0;
        glow += max((modc(length(p3) - time*3, 15.0) - 12.0)*0.7, 0.0);
        float2 p2 = pattern(p3.xz*0.5);
        if(p2.x<1.3) { glow = 0.0; }
    }
#endif // ENABLE_PATTERN
    glow += max(1.0-abs(dot(-GetCameraForward(), normal)) - 0.4, 0.0) * 1.0;
    float3 emission = float3(0.7, 0.7, 1.0)*glow*0.6;

    gbuffer_out O;
    O.diffuse = float4(0.75, 0.75, 0.80, 1.0);
    O.spec_smoothness = float4(0.2, 0.2, 0.2, _Glossiness);
    O.normal = float4(normal*0.5+0.5, 1.0);
    O.emission = float4(emission, 1.0);
#ifndef UNITY_HDR_ON
    O.emission = exp2(-O.emission);
#endif
    O.depth = ComputeDepth(mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0)));
    return O;
}

struct distance_out
{
    float4 distance : SV_Target0;
    //half steps : SV_Target1;
};

struct opass_out
{
    float distance : SV_Target0;
    half diff : SV_Target1;
};

#define DIFF_THRESHILD 0.0001

opass_out frag_opass(vs_out I)
{
#if UNITY_UV_STARTS_AT_TOP
    I.spos.y *= -1.0;
#endif
    float2 tpos = I.spos.xy*0.5+0.5;
    float2 pos = I.spos.xy;
    pos.x *= _ScreenParams.x / _ScreenParams.y;

    float num_steps, last_distance, total_distance = _ProjectionParams.y;
    float3 ray_pos;
    raymarching(pos, MAX_MARCH_OPASS, total_distance, num_steps, last_distance, ray_pos);

    opass_out O;
    O.distance = total_distance;
    O.diff = total_distance - tex2D(g_depth_prev, tpos).x;
    return O;
}


distance_out adaptive_pass(vs_out I, const int max_steps)
{
#if UNITY_UV_STARTS_AT_TOP
    I.spos.y *= -1.0;
#endif
    float2 tpos = I.spos.xy*0.5+0.5;
    float2 pos = I.spos.xy;
    pos.x *= _ScreenParams.x / _ScreenParams.y;

    float num_steps, last_distance, total_distance = sample_upper_depth(tpos);
    float3 ray_pos;
#if ENABLE_TEMPORAL
    if(abs(tex2D(g_velocity, tpos).x) < DIFF_THRESHILD) {
        total_distance = max(total_distance, sample_prev_depth(tpos));
    }
#endif
    raymarching(pos, max_steps, total_distance, num_steps, last_distance, ray_pos);

    distance_out O;
    O.distance = total_distance;
    return O;
}

distance_out frag_qpass(vs_out v) { return adaptive_pass(v, MAX_MARCH_QPASS); }
distance_out frag_hpass(vs_out v) { return adaptive_pass(v, MAX_MARCH_HPASS); }
distance_out frag_apass(vs_out v) { return adaptive_pass(v, MAX_MARCH_APASS); }


sampler2D g_qsteps;
sampler2D g_hsteps;
sampler2D g_asteps;
half4 frag_show_steps(vs_out I) : SV_Target0
{
    float2 t = I.spos.xy*0.5+0.5;
    float3 l = float3(tex2D(g_qsteps, t).x, tex2D(g_hsteps, t).x, tex2D(g_asteps, t).x);
    return float4(l.xyz, 1.0);
}

ENDCG

SubShader {
    Tags{ "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10" }
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
#pragma multi_compile ___ ENABLE_SCREENSPACE
#pragma multi_compile ___ ENABLE_ADAPTIVE
#pragma multi_compile ___ ENABLE_PATTERN
ENDCG
    }
    
    Pass {
        Name "ODepth"
        ZWrite Off
        ZTest Always
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_opass
#pragma multi_compile ___ ENABLE_SCREENSPACE
ENDCG
    }

    Pass {
        Name "QDepth"
        ZWrite Off
        ZTest Always
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_qpass
#pragma multi_compile ___ ENABLE_SCREENSPACE
#pragma multi_compile ___ ENABLE_TEMPORAL
ENDCG
    }

    Pass {
        Name "HDepth"
        ZWrite Off
        ZTest Always
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_hpass
#pragma multi_compile ___ ENABLE_SCREENSPACE
#pragma multi_compile ___ ENABLE_TEMPORAL
ENDCG
    }
    
    Pass {
        Name "ADepth"
        ZWrite Off
        ZTest Always
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_apass
#pragma multi_compile ___ ENABLE_SCREENSPACE
#pragma shader_feature ___ ENABLE_TEMPORAL
ENDCG
    }

    Pass {
        Name "ShowSteps"
        ZWrite Off
        ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_show_steps
ENDCG
    }
}
Fallback Off
}
