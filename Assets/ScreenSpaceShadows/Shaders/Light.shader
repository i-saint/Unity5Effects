Shader "Hidden/ScreenSpaceShadowLight" {
Properties {
}
SubShader {
    Tags { "RenderType"="Opaque" }
    Blend Off
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#define POINT
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityDeferredLibrary.cginc"
#include "Assets/GBufferUtils/Shaders/GBufferUtils.cginc"

sampler2D _BackDepth;
float4 _Position;
float4 _Color;
float4 _Params;
#define _Range          _Position.w
#define _InnerRadius    _Params.x
#define _CapsuleLength  _Params.y
#define _CustomLightInvSqRadius _Params.z



#define MAX_MARCH 64


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
    half4 color : SV_Target0;
};


unity_v2f_deferred vert_point(ia_out v)
{
    v.vertex.xyz *= _Range;

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



half3 CalcSphereLightToLight(float3 pos, float3 lightPos, float3 eyeVec, half3 normal, float sphereRad)
{
    half3 viewDir = -eyeVec;
    half3 r = reflect (viewDir, normal);

    float3 L = lightPos - pos;
    float3 centerToRay = dot (L, r) * r - L;
    float3 closestPoint = L + centerToRay * saturate(sphereRad / length(centerToRay));
    return normalize(closestPoint);
}

half3 CalcTubeLightToLight(float3 pos, float3 tubeStart, float3 tubeEnd, float3 eyeVec, half3 normal, float tubeRad)
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
    
    float3 closestPoint	= L0 + Ld * clamp( t, 0.0, 1.0 );
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
    float3 wpos = mul (_CameraToWorld, vpos).xyz;
    
    float3 lightPos = float3(_Object2World[0][3], _Object2World[1][3], _Object2World[2][3]);

    // Point light
    float3 tolight = wpos - lightPos;
    half3 lightDir = -normalize (tolight);
    
    float att = dot(tolight, tolight) * _CustomLightInvSqRadius;
    float atten = tex2D (_LightTextureB0, att.rr).UNITY_ATTEN_CHANNEL;

    outWorldPos = wpos;
    outUV = uv;
    outLightDir = lightDir;
    outAtten = atten;
    outFadeDist = 0;
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

    float2 coord = i.uv.xy / i.uv.w;

    ps_out r;
    r.color = 0.0;

    float depth = GetDepth(coord);
    float4 p = GetPosition(coord);
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos);

    float3 diff = p.xyz - _Position.xyz;
    float distance = length(diff);
    float march_step = distance / MAX_MARCH;
    float3 ray_dir = diff / distance;

    float hit = 0.0;
    float hit_coord;
    float ray_depth;
    float ref_depth;
    float3 ray_pos;
    for(int k=1; k<MAX_MARCH; ++k) {
        float adv = march_step * k;
        ray_pos = _Position.xyz + ray_dir * adv;
        float4 ray_pos4 = mul(UNITY_MATRIX_MVP, float4(ray_pos, 1.0));
        ray_pos4.y *= _ProjectionParams.x;
        float2 ray_coord = ray_pos4.xy / ray_pos4.w * 0.5 + 0.5 + HalfPixelSize;
        ray_depth = ComputeDepth(ray_pos4);
        ref_depth = GetDepth(ray_coord);
#if ENABLE_BACKDEPTH
#endif

        if(ray_depth > ref_depth) {
            hit = 1.0;
            hit_coord = ray_coord;
            break;
        }
    }

    // todo
    float4 albedo = GetAlbedo(coord);
    float4 specular = GetSpecular(coord);
    float4 normal = GetNormal(coord);

    //half3 CalcSphereLightToLight(p.xyz, float3 lightPos, float3 eyeVec, half3 normal, float sphereRad)

    //UnityLight light = (UnityLight)0;
    //DeferredCalculateLightParams (i, wpos, uv, light.dir, atten, fadeDist);
    //r.color.rgb += CalcSphereLightToLight(p.xyz, _Position.xyz, cam_dir, normal, ) * (1.0-hit);

    r.color += _Color;
    r.color.rgb = wpos * 0.2;
    return r;
}

ps_out frag_line(unity_v2f_deferred i)
{
    return frag_point(i); // todo
}
ENDCG

    // point light
    Pass {
        Fog { Mode Off }
        ZWrite Off
        ZTest Always
        //Blend One One
        Cull Front

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt
        //#pragma multi_compile QUALITY_FAST QUALITY_MEDIUM QUALITY_HIGH
        //#pragma multi_compile ___ ENABLE_BACKDEPTH
        #pragma vertex vert_point
        #pragma fragment frag_point
        ENDCG
    }

    // line light
    Pass {
        Fog { Mode Off }
        ZWrite Off
        ZTest Always
        Blend One One
        Cull Front

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt
        //#pragma multi_compile QUALITY_FAST QUALITY_MEDIUM QUALITY_HIGH
        //#pragma multi_compile ___ ENABLE_BACKDEPTH
        #pragma vertex vert_line
        #pragma fragment frag_line
        ENDCG
    }
}
}
