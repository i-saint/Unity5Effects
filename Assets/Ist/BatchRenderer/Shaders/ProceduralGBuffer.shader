Shader "BatchRenderer/ProceduralGBuffer" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0
    _EmissionMap ("Emission Map", 2D) = "white" {}
    _Emission ("EmissionColor", Color) = (1,1,1,1)
    _Offset ("Offset", Vector) = (0,0,0,1)
}

CGINCLUDE
#define ENABLE_INSTANCE_BUFFER 1

#include "UnityStandardCore.cginc"
#include "BatchRenderer.cginc"
#include "Surface.cginc"

struct vertex_t
{
    float3 position;
    float3 normal;
    float4 tangent;
    float2 texcoord;
};
StructuredBuffer<vertex_t> g_vertices;
sampler2D _NormalMap;
sampler2D _SpecularMap;
sampler2D _GrossMap;
fixed4 g_base_color;
fixed4 _Emission;
float3 _Offset;


struct ia_out
{
    uint vertexID : SV_VertexID;
    uint instanceID : SV_InstanceID;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 spos : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float4 tangent : TEXCOORD2;
    float2 texcoord : TEXCOORD3;
};

struct ps_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
};


vs_out vert(ia_out v)
{
    int vid = v.vertexID;
    int iid = v.instanceID;
    float4 pos      = float4(g_vertices[vid].position, 1.0);
    pos.xyz += _Offset;
    float3 normal   = g_vertices[vid].normal;
    float4 tangent  = g_vertices[vid].tangent;
    float2 texcoord = g_vertices[vid].texcoord;
    float4 color = 0.0;
    float4 emission = 0.0;

    ApplyInstanceTransform(iid, pos, normal, tangent, texcoord, color, emission);
    float4 vp = mul(UNITY_MATRIX_VP, pos);

    vs_out o;
    o.vertex = vp;
    o.spos = vp;
    o.normal = normal;
    o.tangent = tangent;
    o.texcoord = texcoord;
    return o;
}


ps_out frag(vs_out v)
{
    ps_out r;
    r.diffuse = tex2D(_MainTex, v.texcoord) * _Color;
    r.spec_smoothness = _Glossiness;
    r.normal = float4(v.normal*0.5+0.5, 0.0);
    r.emission = tex2D(_EmissionMap, v.texcoord) * _Emission;
    return r;
}
ENDCG

SubShader {
    Tags { "RenderType"="Opaque" }
    Cull Off

    Pass {
        Name "DEFERRED"
        Tags { "LightMode" = "Deferred" }
        Stencil {
            Comp Always
            Pass Replace
            Ref 128
        }
CGPROGRAM
#pragma target 5.0
#pragma vertex vert
#pragma fragment frag

#pragma multi_compile ___ ENABLE_INSTANCE_ROTATION
#pragma multi_compile ___ ENABLE_INSTANCE_SCALE
#pragma multi_compile ___ ENABLE_INSTANCE_EMISSION
#pragma multi_compile ___ ENABLE_INSTANCE_UVOFFSET
#pragma multi_compile ___ ENABLE_INSTANCE_COLOR

ENDCG
    }
}
Fallback Off
}
