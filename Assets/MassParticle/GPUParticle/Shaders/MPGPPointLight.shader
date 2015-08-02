Shader "GPUParticle/PointLight" {

Properties {
    _SrcBlend("Src Blend", Int) = 1
    _DstBlend("Dst Blend", Int) = 1
    _Color("Color ", Vector) = (1,1,1,1)
    g_size("Particle Size", Float) = 0.5
    g_fade_time("Fade Time", Float) = 0.3
    g_spin("Spin", Float) = 0.0
}

SubShader {

CGINCLUDE
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityDeferredLibrary.cginc"
#include "MPGPFoundation.cginc"
#include "Assets/IstEffects/GBufferUtils/Shaders/GBufferUtils.cginc"

#define _Range              (g_size*0.5)
#define _RangeInvSq         (1.0/(_Range*_Range))
#define _InnerRadius        0


#if (defined(SHADER_API_D3D11) || defined(SHADER_API_PSSL))
    #define MPGP_WITH_STRUCTURED_BUFFER
#endif

#ifdef MPGP_WITH_STRUCTURED_BUFFER
StructuredBuffer<Particle> particles;
#endif // MPGP_WITH_STRUCTURED_BUFFER
int         g_batch_begin;
float       g_size;
float       g_fade_time;
float4      _Color;


int ParticleTransform(inout appdata_full v, out float4 pos)
{
    int iid = v.texcoord1.x + g_batch_begin;
#ifdef MPGP_WITH_STRUCTURED_BUFFER
    Particle p = particles[iid];
    if (p.lifetime <= 0.0) {
        v.vertex.xyz = 0.0;
        return iid;
    }
    v.vertex.xyz *= g_size * min(1.0, p.lifetime / g_fade_time);
    v.vertex.xyz += p.position.xyz;
    pos = float4(p.position.xyz, iid);
#endif // MPGP_WITH_STRUCTURED_BUFFER
    return iid;
}


struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 uv : TEXCOORD0;
    float4 instance_pos : TEXCOORD1; // w: instance id
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
    float4 ipos = 0;
    ParticleTransform(v, ipos);

    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv = ComputeScreenPos(o.vertex);
    o.instance_pos = ipos;
    return o;
}



half3 CalcSphereLightToLight(float3 worldPos, float3 lightPos, float3 eyeVec, half3 normal, float sphereRad, out float3 closestPoint)
{
    half3 viewDir = -eyeVec;
    half3 r = reflect(viewDir, normal);

    float3 L = lightPos - worldPos;
    float3 centerToRay = dot(L, r) * r - L;
    closestPoint = L + centerToRay * saturate(sphereRad / length(centerToRay));
    return normalize(closestPoint);
}

half3 CalcTubeLightToLight(float3 pos, float3 tubeStart, float3 tubeEnd, float3 eyeVec, half3 normal, float tubeRad, out float3 closestPoint)
{
    half3 N = normal;
    half3 viewDir = -eyeVec;
    half3 r = reflect(viewDir, normal);

    float3 L0 = tubeStart - pos;
    float3 L1 = tubeEnd - pos;
    float distL0 = length(L0);
    float distL1 = length(L1);

    float NoL0 = dot(L0, N) / (2.0 * distL0);
    float NoL1 = dot(L1, N) / (2.0 * distL1);
    float NoL = (2.0 * clamp(NoL0 + NoL1, 0.0, 1.0))
        / (distL0 * distL1 + dot(L0, L1) + 2.0);

    float3 Ld = L1 - L0;
    float RoL0 = dot(r, L0);
    float RoLd = dot(r, Ld);
    float L0oLd = dot(L0, Ld);
    float distLd = length(Ld);
    float t = (RoL0 * RoLd - L0oLd)
        / (distLd * distLd - RoLd * RoLd);

    closestPoint = L0 + Ld * clamp(t, 0.0, 1.0);
    float3 centerToRay = dot(closestPoint, r) * r - closestPoint;
    closestPoint = closestPoint + centerToRay * clamp(tubeRad / length(centerToRay), 0.0, 1.0);
    float3 l = normalize(closestPoint);
    return l;
}

void DeferredCalculateLightParams(
    float3 worldPos,
    float3 lightPos,
    out half3 outLightDir,
    out float outAtten,
    out float outFadeDist)
{
    // Point light
    float3 tolight = worldPos - lightPos;
    half3 lightDir = -normalize(tolight);

    float att = dot(tolight, tolight) * _RangeInvSq;
    float atten = tex2D(_LightTextureB0, att.rr).UNITY_ATTEN_CHANNEL;

    outLightDir = lightDir;
    outAtten = atten;
    outFadeDist = 0;
}


// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

ps_out frag(vs_out i)
{
    int instance_id = i.instance_pos.w;
    float2 uv = i.uv.xy / i.uv.w;
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
    float2 screen_pos = uv.xy * 2.0 - 1.0;
    float4 wpos4 = mul(_InvViewProj, float4(screen_pos, depth, 1.0));
    float3 wpos = wpos4.xyz / wpos4.w;
    float3 lightPos = i.instance_pos.xyz;

    float atten, fadeDist;
    UnityLight light = (UnityLight)0;
    DeferredCalculateLightParams(wpos, lightPos, light.dir, atten, fadeDist);


    half4 gbuffer0 = tex2D(_CameraGBufferTexture0, uv);
    half4 gbuffer1 = tex2D(_CameraGBufferTexture1, uv);
    half4 gbuffer2 = tex2D(_CameraGBufferTexture2, uv);
    half3 normalWorld = gbuffer2.rgb * 2 - 1;
    normalWorld = normalize(normalWorld);
    float3 eyeVec = normalize(wpos - _WorldSpaceCameraPos);

    float3 lightClosestPoint;
    light.dir = CalcSphereLightToLight(wpos, lightPos, eyeVec, normalWorld, _InnerRadius, lightClosestPoint);
    light.ndotl = LambertTerm(normalWorld, light.dir);
    if (dot(gbuffer2.xyz, 1.0) * light.ndotl <= 0.0) { discard; }

    light.color = _Color.rgb * atten;
    half3 baseColor = gbuffer0.rgb;
    half3 specColor = gbuffer1.rgb;
    half oneMinusRoughness = gbuffer1.a;

    half oneMinusReflectivity = 1 - SpecularStrength(specColor.rgb);

    UnityIndirect ind;
    UNITY_INITIALIZE_OUTPUT(UnityIndirect, ind);
    ind.diffuse = 0;
    ind.specular = 0;

    half4 res = UNITY_BRDF_PBS(baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normalWorld, -eyeVec, light, ind);
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
#pragma vertex vert
#pragma fragment frag
        ENDCG
    }
}

FallBack Off
}
