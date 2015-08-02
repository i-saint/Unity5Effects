Shader "MassParticle/Standard Spherify" {

Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _Color ("Color", Color) = (0.8, 0.8, 0.8, 1.0)
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0
    g_size ("Particle Size", Float) = 0.2
    g_fade_time ("Fade Time", Float) = 0.3
    g_radius ("Radius", Float) = 0.02
}

CGINCLUDE
float g_radius;
ENDCG

SubShader {
    Tags { "RenderType"="Opaque" }

CGPROGRAM
#pragma surface surf Standard fullforwardshadows vertex:vert
#pragma target 4.0
#include "MPFoundation.cginc"

sampler2D _MainTex;
fixed4 _Color;
half _Glossiness;
half _Metallic;

struct Input {
    float2 uv_MainTex;
    float4 position;
    float3 normal;
    float3 binormal;
    float3 tangent;
    float3 instance_pos;
    float4 velocity;
};

void vert(inout appdata_full v, out Input data)
{
    UNITY_INITIALIZE_OUTPUT(Input,data);

    float4 pos;
    float4 vel;
    float4 params;
    ParticleTransform(v, pos, vel, params);

    float lifetime = params.y;

    data.position = v.vertex;
    data.normal = v.normal.xyz;
    data.tangent = v.tangent.xyz;
    data.binormal = normalize(cross(v.normal.xyz, v.tangent.xyz) * v.tangent.w);
    data.velocity = vel;
    data.instance_pos = pos;
}

void surf(Input IN, inout SurfaceOutputStandard o)
{
    float3 sphere_pos = IN.instance_pos.xyz;
    float sphere_radius = g_radius;

    float3 s_normal = normalize(_WorldSpaceCameraPos.xyz - IN.position.xyz);
    float3 pos_rel = IN.position.xyz - sphere_pos;
    float s_dist = dot(pos_rel, s_normal);
    float3 pos_proj = IN.position.xyz - s_dist*s_normal;

    float dist_proj = length(pos_proj-sphere_pos);
    if(dist_proj>sphere_radius) {
        discard;
    }

    float len = length(pos_rel);
    if(len<sphere_radius) {
        o.Normal = IN.normal;
        //o.position = float4(IN.position.xyz, IN.screen_pos.z);
    }
    else {
        float s_dist2 = length(pos_proj-sphere_pos);
        float s_dist3 = sqrt(sphere_radius*sphere_radius - s_dist2*s_dist2);
        float3 ps = pos_proj + s_normal * s_dist3;

        float3 dir = normalize(ps-sphere_pos);
        float3 pos = sphere_pos+dir*sphere_radius;
        float4 spos = mul(UNITY_MATRIX_VP, float4(pos,1.0));
        o.Normal = float4(dir, 0.0);
        //o.position = float4(pos, spos.z);
    }

    float3x3 tbn = float3x3(IN.tangent.xyz, IN.binormal, IN.normal.xyz);
    o.Normal = normalize(mul(o.Normal, transpose(tbn)));


    fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
    o.Albedo = c.rgb;
    o.Metallic = _Metallic;
    o.Smoothness = _Glossiness;
    o.Alpha = c.a;

    float speed = IN.velocity.w;
    float ei = max(speed-2.0, 0.0) * 1.0;
    o.Emission = float3(0.25, 0.05, 0.025)*ei;
}
ENDCG

    Pass {
        Name "ShadowCaster"
        Tags { "LightMode" = "ShadowCaster" }
        
        Fog {Mode Off}
        ZWrite On ZTest LEqual Cull Off
        Offset 1, 1

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_shadowcaster
#include "UnityCG.cginc"
#include "MPFoundation.cginc"

struct v2f { 
    V2F_SHADOW_CASTER;
};

v2f vert(appdata_full v)
{
    float4 pos;
    float4 vel;
    float4 params;
    ParticleTransform(v, pos, vel, params);

    v2f o;
    TRANSFER_SHADOW_CASTER(o)
    return o;
}


float4 frag(v2f IN) : SV_Target
{
    SHADOW_CASTER_FRAGMENT(IN)
}
ENDCG
    }

}
FallBack Off

}
