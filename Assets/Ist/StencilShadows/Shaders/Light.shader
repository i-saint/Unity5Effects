// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/Ist/StencilShadows/Light" {
Properties {
    _SrcBlend("", Int) = 1
    _DstBlend("", Int) = 1
    _StencilReadMask("", Int) = 7
    _StencilWriteMask("", Int) = 7
}
SubShader {
    Tags { "RenderType"="Opaque" }
    Fog{ Mode Off }

    ZWrite Off
    ZTest Always
    Blend[_SrcBlend][_DstBlend]
    Cull Front

CGINCLUDE
#define POINT
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityDeferredLibrary.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

sampler2D _Occulusion;
float4 _Position;
float4 _Color;
float4 _Params1;
#define _Range              _Position.w
#define _RangeInvSq         (1.0/(_Range*_Range))
#define _InnerRadius        _Params1.x
#define _CapsuleLength      _Params1.y
#define _LightType          _Params1.z
#define _OcculusionStrength _Params1.w


struct ia_out
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
};

struct ps_out
{
#if UNITY_HDR_ON
    half4
#else
    fixed4
#endif
        color : SV_Target0;
};


unity_v2f_deferred vert_point(ia_out v)
{
    unity_v2f_deferred o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv = ComputeScreenPos(o.pos);
    o.ray = mul (UNITY_MATRIX_MV, v.vertex).xyz * float3(-1,-1,1);
    return o;
}


unity_v2f_deferred vert_line(ia_out v)
{
    return vert_point(v);
}



half3 CalcSphereLightToLight(float3 pos, float3 lightPos, float3 eyeVec, half3 normal, float sphereRad, out float3 closestPoint)
{
    half3 viewDir = -eyeVec;
    half3 r = reflect (viewDir, normal);

    float3 L = lightPos - pos;
    float3 centerToRay = dot (L, r) * r - L;
    closestPoint = L + centerToRay * saturate(sphereRad / length(centerToRay));
    return normalize(closestPoint);
}

half3 CalcTubeLightToLight(float3 pos, float3 tubeStart, float3 tubeEnd, float3 eyeVec, half3 normal, float tubeRad, out float3 closestPoint)
{
    half3 N = normal;
    half3 viewDir = -eyeVec;
    half3 r = reflect (viewDir, normal);

    float3 L0		= tubeStart - pos;
    float3 L1		= tubeEnd - pos;
    float distL0	= length( L0 );
    float distL1	= length( L1 );
    
    float NoL0		= dot( L0, N ) / ( 2.0 * distL0 );
    float NoL1		= dot( L1, N ) / ( 2.0 * distL1 );
    float NoL		= ( 2.0 * clamp( NoL0 + NoL1, 0.0, 1.0 ) ) 
                    / ( distL0 * distL1 + dot( L0, L1 ) + 2.0 );
    
    float3 Ld			= L1 - L0;
    float RoL0		= dot( r, L0 );
    float RoLd		= dot( r, Ld );
    float L0oLd 	= dot( L0, Ld );
    float distLd	= length( Ld );
    float t			= ( RoL0 * RoLd - L0oLd ) 
                    / ( distLd * distLd - RoLd * RoLd );
    
    closestPoint	= L0 + Ld * clamp( t, 0.0, 1.0 );
    float3 centerToRay	= dot( closestPoint, r ) * r - closestPoint;
    closestPoint		= closestPoint + centerToRay * clamp( tubeRad / length( centerToRay ), 0.0, 1.0 );
    float3 l				= normalize( closestPoint );
    return l;
}

void DeferredCalculateLightParams (
    unity_v2f_deferred i,
    out float3 outWorldPos,
    out float2 outUV,
    out half3 outLightDir,
    out float outAtten,
    out float outFadeDist)
{
    i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
    float2 uv = i.uv.xy / i.uv.w;
    
    // read depth and reconstruct world position
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
    depth = Linear01Depth (depth);
    float4 vpos = float4(i.ray * depth,1);
    float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
    
    float3 lightPos = float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]);

    // Point light
    float3 tolight = wpos - lightPos;
    half3 lightDir = -normalize (tolight);
#if ENABLE_INVERSE
    lightPos += lightDir * _Range;
    lightDir *= -1.0;
    float atten = 1.0;
#else
    float att = dot(tolight, tolight) * _RangeInvSq;
    float atten = tex2D (_LightTextureB0, att.rr).UNITY_ATTEN_CHANNEL;
#endif
#if ENABLE_SHADOW
    atten *= min(tex2D(_Occulusion, uv).x, 1.0);
#endif

    outWorldPos = wpos;
    outUV = uv;
    outLightDir = lightDir;
    outAtten = atten;
    outFadeDist = 0;
}

float Jitter(float3 p)
{
    float v = dot(p,1.0)+_Time.y;
    return frac(sin(v)*43758.5453);
}


void distance_point_sphere(float3 ppos, float3 center, float radius,
    out float3 direction, out float distance)
{
    float3 diff = ppos - center;
    distance = length(diff)-radius;
    direction = normalize(diff);
}

void distance_point_capsule(float3 ppos, float3 pos1, float3 pos2, float radius,
    out float3 nearest, out float3 direction, out float distance)
{
    float3 d = pos2-pos1;
    float t = dot(ppos-pos1, pos2-pos1) / dot(d,d);
    nearest = pos1 + (pos2-pos1) * clamp(t, 0.0, 1.0);
    float3 diff = ppos-nearest;
    distance = length(diff) - radius;
    direction = normalize(diff);
}

// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

ps_out frag_point(unity_v2f_deferred i)
{
    float3 wpos;
    float2 uv;
    float atten, fadeDist;
    UnityLight light = (UnityLight)0;
    DeferredCalculateLightParams (i, wpos, uv, light.dir, atten, fadeDist);
    
    float3 lightPos = float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]);
#if ENABLE_INVERSE
    lightPos += light.dir * _Range;
    light.dir *= -1.0;
#endif
    float3 lightAxisX = normalize(float3(unity_ObjectToWorld[0][0], unity_ObjectToWorld[1][0], unity_ObjectToWorld[2][0]));
    float3 lightPos1 = lightPos + lightAxisX * _CapsuleLength;
    float3 lightPos2 = lightPos - lightAxisX * _CapsuleLength;

    half4 gbuffer0 = tex2D (_CameraGBufferTexture0, uv);
    half4 gbuffer1 = tex2D (_CameraGBufferTexture1, uv);
    half4 gbuffer2 = tex2D (_CameraGBufferTexture2, uv);
    half3 normalWorld = gbuffer2.rgb * 2 - 1;
    normalWorld = normalize(normalWorld);
    float3 eyeVec = normalize(wpos-_WorldSpaceCameraPos);

    float3 lightClosestPoint;
    if (_LightType == 1)
    {
        // tube light
        light.dir = CalcTubeLightToLight (wpos, lightPos1, lightPos2, eyeVec, normalWorld, _InnerRadius, lightClosestPoint);
    }
    else
    {
        // Sphere light
        light.dir = CalcSphereLightToLight (wpos, lightPos, eyeVec, normalWorld, _InnerRadius, lightClosestPoint);
    }

    light.ndotl = LambertTerm (normalWorld, light.dir);
    if(dot(gbuffer2.xyz, 1.0) * light.ndotl <= 0.0) { discard; }

    float occlusion = 0.0;
    light.color = _Color.rgb * atten;
    half3 baseColor = gbuffer0.rgb;
    half3 specColor = gbuffer1.rgb;
    half oneMinusRoughness = gbuffer1.a;

    half oneMinusReflectivity = 1 - SpecularStrength(specColor.rgb);
    
    UnityIndirect ind;
    UNITY_INITIALIZE_OUTPUT(UnityIndirect, ind);
    ind.diffuse = 0;
    ind.specular = 0;

    half4 res = UNITY_BRDF_PBS (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normalWorld, -eyeVec, light, ind);
    res *= max(1.0-occlusion, 0.0);
#ifndef UNITY_HDR_ON
    res = exp2(-res);
#endif
    ps_out r;
    r.color = res;
    //r.color.rgb = light.dir;
    return r;
}

ps_out frag_line(unity_v2f_deferred i)
{
    return frag_point(i); // todo
}
ENDCG

    // point light
    Pass {
        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt
        #pragma multi_compile ___ ENABLE_SHADOW
        #pragma multi_compile ___ ENABLE_INVERSE
        #pragma multi_compile ___ UNITY_HDR_ON
        #pragma vertex vert_point
        #pragma fragment frag_point
        ENDCG
    }

    // line light
    Pass {
        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt
        #pragma multi_compile ___ ENABLE_SHADOW
        #pragma multi_compile ___ ENABLE_INVERSE
        #pragma multi_compile ___ UNITY_HDR_ON
        #pragma vertex vert_line
        #pragma fragment frag_line
        ENDCG
    }
}
}
