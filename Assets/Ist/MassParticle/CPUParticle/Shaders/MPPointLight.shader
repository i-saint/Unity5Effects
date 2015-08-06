Shader "MassParticle/PointLight" {

Properties {
    _SrcBlend("Src Blend", Int) = 1
    _DstBlend("Dst Blend", Int) = 1

    _Color("Color ", Color) = (1,1,1,1)

    _HeatColor("Heat Color", Color) = (0.25, 0.05, 0.025, 0.0)
    _HeatThreshold("Heat Threshold", Float) = 2.0

    g_size("Particle Size", Float) = 0.5
    g_fade_time("Fade Time", Float) = 0.3
}

SubShader {

CGINCLUDE
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityDeferredLibrary.cginc"
#include "MPFoundation.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"


float4  _Color;
float   _OcculusionStrength;

float4  _HeatColor;
float   _HeatThreshold;


struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 uv : TEXCOORD0;
    float4 instance_pos : TEXCOORD1; // w: 1.0 / (range*range)
    float4 heat_color : TEXCOORD2;
};

struct ps_out
{
#if UNITY_HDR_ON
    half4
#else
    fixed4
#endif
    color: SV_Target0;
};



vs_out vert(appdata_full v)
{
    int iid = v.texcoord1.x + g_batch_begin;
    float4 pos;
    float4 vel;
    float4 params;
    GetParticleParams(iid, pos, vel, params);

    float size = g_size * min(1.0, params.y / g_fade_time);
    v.vertex.xyz *= size;
    v.vertex.xyz += pos.xyz;
    float range = size * 0.5;
    float range_inv_sq = 1.0 / (range*range);

    vs_out O;
    O.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    O.uv = ComputeScreenPos(O.vertex);
    O.instance_pos = float4(pos.xyz, range_inv_sq);

    float speed = vel.w;
    O.heat_color = _HeatColor * max(speed - _HeatThreshold, 0.0);

    return O;
}



void DeferredCalculateLightParams(
    float3 worldPos,
    float3 lightPos,
    float range_inv_sq,
    out half3 outLightDir,
    out float outAtten,
    out float outFadeDist)
{
    float3 tolight = worldPos - lightPos;
    half3 lightDir = -normalize(tolight);
    float att = dot(tolight, tolight) * range_inv_sq;
    float atten = tex2D(_LightTextureB0, att.rr).UNITY_ATTEN_CHANNEL;
    outLightDir = lightDir;
    outAtten = atten;
    outFadeDist = 0;
}

float Jitter(float3 p)
{
    float v = dot(p, 1.0) + _Time.y;
    return frac(sin(v)*43758.5453);
}


// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

#if QUALITY_FAST
    #define MAX_MARCH 4
#elif QUALITY_HIGH
    #define MAX_MARCH 12
#else // QUALITY_MEDIUM
    #define MAX_MARCH 8
#endif

ps_out frag(vs_out I)
{
    int instance_id = I.instance_pos.w;
    float2 uv = I.uv.xy / I.uv.w;
    float3 wpos = GetPosition(uv).xyz;
    float3 lightPos = I.instance_pos.xyz;
    float range_inv_sq = I.instance_pos.w;

    float atten, fadeDist;
    UnityLight light = (UnityLight)0;
    DeferredCalculateLightParams(wpos, lightPos, range_inv_sq, light.dir, atten, fadeDist);


    half4 gbuffer0 = tex2D(_CameraGBufferTexture0, uv);
    half4 gbuffer1 = tex2D(_CameraGBufferTexture1, uv);
    half4 gbuffer2 = tex2D(_CameraGBufferTexture2, uv);
    half3 normalWorld = gbuffer2.rgb * 2 - 1;
    normalWorld = normalize(normalWorld);
    float3 eyeVec = normalize(wpos - _WorldSpaceCameraPos);

    light.dir = normalize(lightPos - wpos);
    light.ndotl = LambertTerm(normalWorld, light.dir);
    if (dot(gbuffer2.xyz, 1.0) * light.ndotl <= 0.0) { discard; }

    float occlusion = 0.0;
#if ENABLE_SHADOW
    {
        float distance;
        float3 ray_dir;
        float occulusion_par_march = _OcculusionStrength / MAX_MARCH;
        float3 diff = wpos.xyz - lightPos.xyz;
        distance = length(diff);
        ray_dir = normalize(diff);
        float3 begin_pos = lightPos;
        float march_step = distance / MAX_MARCH;
        float jitter = Jitter(wpos);
        for (int k = 0; k<MAX_MARCH; ++k) {
            float adv = march_step * (float(k) + jitter);
            float3 ray_pos = begin_pos.xyz + ray_dir * adv;
            float4 ray_pos4 = mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0));
            ray_pos4.y *= _ProjectionParams.x;
            float2 ray_coord = ray_pos4.xy / ray_pos4.w * 0.5 + 0.5 + HalfPixelSize;
            float ray_depth = ComputeDepth(ray_pos4);
            float ref_depth = GetDepth(ray_coord);

            //if (ray_depth > ref_depth) {
            //    occlusion += occulusion_par_march;
            //}
            occlusion += occulusion_par_march * clamp((ray_depth - ref_depth)*10000000000.0, 0.0, 1.0);
        }
        occlusion = min(occlusion, clamp(distance * 10000, 0.0, 1.0)); // 0.0 if wpos is inner light inner radius
    }
    //if(occlusion >= 1.0) { discard; } // this makes slower
#endif


    light.color = (_Color.rgb + I.heat_color) * atten;
    half3 baseColor = gbuffer0.rgb;
    half3 specColor = gbuffer1.rgb;
    half oneMinusRoughness = gbuffer1.a;

    half oneMinusReflectivity = 1 - SpecularStrength(specColor.rgb);

    UnityIndirect ind;
    UNITY_INITIALIZE_OUTPUT(UnityIndirect, ind);
    ind.diffuse = 0;
    ind.specular = 0;

    half4 res = UNITY_BRDF_PBS(baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normalWorld, -eyeVec, light, ind);
    res *= max(1.0 - occlusion, 0.0);
#ifndef UNITY_HDR_ON
    res = exp2(-res);
#endif
    ps_out r;
    r.color = res;
    return r;
}

ENDCG

    // point light
    Pass{
        Fog{ Mode Off }
        ZWrite Off
        ZTest Greater
        Blend[_SrcBlend][_DstBlend]
        Cull Front

        CGPROGRAM
#pragma target 3.0
#pragma exclude_renderers nomrt
#pragma multi_compile ___ UNITY_HDR_ON
#pragma multi_compile ___ ENABLE_SHADOW
#pragma multi_compile QUALITY_FAST QUALITY_MEDIUM QUALITY_HIGH
#pragma vertex vert
#pragma fragment frag
        ENDCG
    }
}

FallBack Off
}
