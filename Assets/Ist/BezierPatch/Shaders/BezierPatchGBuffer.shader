Shader "Ist/BezierPatch/GBuffer" {
Properties {
    _Color("Color", Color) = (0.5, 0.5, 0.5, 0.5)
    _SpecularColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
    _EmissionColor("Emission Color", Color) = (0.0, 0.0, 0.0, 0.0)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness("Smoothness", Range(0,1)) = 0.5
    _Metallic("Metallic", Range(0, 1)) = 0.0
    _Epsilon("Epsilon", Float) = 0.01
}

CGINCLUDE
#include "UnityStandardCore.cginc"
#include "Assets/Ist/Foundation/Shaders/Math.cginc"
#include "Assets/Ist/Foundation/Shaders/Geometry.cginc"
#include "Assets/Ist/Foundation/Shaders/BuiltinVariablesExt.cginc"
#include "Assets/Ist/Foundation/Shaders/BezierPatch.cginc"
#include "Assets/Ist/Foundation/Shaders/BezierPatchIntersection.cginc"


struct Vertex
{
    float3 position;
};

StructuredBuffer<Vertex>        _Vertices;
StructuredBuffer<BezierPatch>   _BezierPatches;
StructuredBuffer<AABB>          _AABBs;
sampler2D   _AdaptiveBuffer;
float4      _SpecularColor;
float       _Epsilon;



struct ia_out
{
    uint vertex_id      : SV_VertexID;
    uint instance_id    : SV_InstanceID;
};

struct vs_out
{
    float4  vertex      : SV_POSITION;
    float4  screen_pos  : TEXCOORD0;
    float4  world_pos   : TEXCOORD1;
    uint    instance_id : TEXCOORD2;
};


vs_out vert(ia_out I)
{
    uint vid = I.vertex_id;
    uint iid = I.instance_id;

    AABB aabb = _AABBs[iid];
    float4 vertex = float4((_Vertices[vid].position * (aabb.extents * 2.0)) + aabb.center, 1.0);

    vs_out O;
    O.vertex = mul(UNITY_MATRIX_MVP, vertex);
    //O.screen_pos = ComputeScreenPos(O.vertex);
    O.screen_pos = O.vertex;
    O.world_pos = mul(_Object2World, vertex);
    O.instance_id = iid;
    return O;
}



struct gbuffer_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
    float depth             : SV_DepthGreaterEqual;
};

gbuffer_out frag_gbuffer(vs_out I)
{
    float3 world_pos = I.world_pos.xyz;
    I.screen_pos.xy /= I.screen_pos.w;
#if UNITY_UV_STARTS_AT_TOP
    I.screen_pos.y *= -1.0;
#endif
    float2 spos = I.screen_pos.xy;
    spos.x *= _ScreenParams.x / _ScreenParams.y;

    uint iid = I.instance_id;
    BezierPatch bpatch = _BezierPatches[iid];

    AABB aabb = _AABBs[iid];
    float zmin = 0.0;
    float zmax = length(aabb.extents) * 2.0;

    Ray ray = GetCameraRay(spos);
#if ENABLE_ADAPTIVE
    ray.origin += ray.direction * tex2D(_AdaptiveBuffer, spos*0.5+0.5).x;
#else
    ray.origin = world_pos;
#endif

    BezierPatchHit hit;
    if (!BPIRaycast(bpatch, ray, zmin, zmax, _Epsilon, hit)) {
        discard;
    }

    float3 bp_pos = ray.origin + ray.direction * hit.t;
    float3 bp_normal = BPEvaluateNormal(bpatch, float2(hit.u, hit.v));

    gbuffer_out O;
    O.diffuse = _Color;

    O.spec_smoothness = float4(_SpecularColor.rgb, _Glossiness);
    O.normal = float4(bp_normal*0.5+0.5, 1.0);
    O.emission = _EmissionColor;
#ifndef UNITY_HDR_ON
    O.emission = exp2(-O.emission);
#endif
    O.depth = ComputeDepth(mul(UNITY_MATRIX_VP, float4(bp_pos, 1.0)));
    return O;
}



struct distance_out
{
    float4 distance : SV_Target0;
#if ENABLE_DEPTH_OUTPUT
    float depth : SV_DepthGreaterEqual;
#endif
};

distance_out frag_distance(vs_out I)
{
    float3 world_pos = I.world_pos.xyz;
    I.screen_pos.xy /= I.screen_pos.w;
#if UNITY_UV_STARTS_AT_TOP
    I.screen_pos.y *= -1.0;
#endif
    float2 spos = I.screen_pos.xy;
    spos.x *= _ScreenParams.x / _ScreenParams.y;


    uint iid = I.instance_id;
    BezierPatch bpatch = _BezierPatches[iid];
    AABB aabb = _AABBs[iid];
    float zmin = 0.0;
    float zmax = length(aabb.extents) * 2.0;

    Ray ray = GetCameraRay(spos);
    ray.origin = world_pos;

    BezierPatchHit hit;
    if (!BPIRaycast(bpatch, ray, zmin, zmax, _Epsilon, hit)) {
        discard;
    }

    float3 bp_pos = ray.origin + ray.direction * hit.t;

    distance_out O;
    O.distance = length(bp_pos - GetCameraPosition());
#if ENABLE_DEPTH_OUTPUT
    O.depth = ComputeDepth(mul(UNITY_MATRIX_VP, float4(bp_pos, 1.0)));
#endif
    return O;
}

ENDCG

SubShader {
    Tags{ "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10" }
    Cull Off

    // g-buffer pass
    Pass {
        Tags { "LightMode" = "Deferred" }
        Stencil {
            Comp Always
            Pass Replace
            Ref 128
        }

        ZWrite On
CGPROGRAM
#pragma target 5.0
#pragma vertex vert
#pragma fragment frag_gbuffer
#pragma multi_compile ___ UNITY_HDR_ON
#pragma multi_compile ___ ENABLE_ADAPTIVE
ENDCG
    }

     Pass{
        Name "ShadowCaster"
        Tags{ "LightMode" = "ShadowCaster" }

        ZWrite On
        ColorMask 0
CGPROGRAM
#pragma target 5.0
#pragma vertex vert
#pragma fragment frag_distance
#define ENABLE_DEPTH_OUTPUT 1
ENDCG
    }

    // adaptive pre pass
    Pass {
        ZWrite Off
CGPROGRAM
#pragma target 5.0
#pragma vertex vert
#pragma fragment frag_distance
ENDCG
    }
}
Fallback Off
}
