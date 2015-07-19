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
#include "UnityCG.cginc"
#include "Assets/GBufferUtils/Shaders/GBufferUtils.cginc"

sampler2D _BackDepth;
float4 _Position;
float4 _Color;
float4 _Params;
#define _Range          _Position.w
#define _InnerRadius    _Params.x
#define _CapsuleLength  _Params.y


#define MAX_MARCH 32


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


vs_out vert_point(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, float4(v.vertex.xyz*_Range, 1.0));
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
}

vs_out vert_line(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, v.vertex * _Range);
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
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


// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

ps_out frag_point(vs_out i)
{
    float2 coord = (i.screen_pos.xy / i.screen_pos.w) * 0.5 + 0.5 + HalfPixelSize;

    ps_out r;
    r.color = 0.0;

    float depth = GetDepth(coord);
    float4 p = GetPosition(coord);
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos);

    float3 diff = p.xyz - _Position.xyz;
    float distance = length(diff);
    float march_step = distance / MAX_MARCH;
    float3 ray_dir = diff / distance;

    for(int k=1; k<MAX_MARCH; ++k) {
        float adv = march_step * k;
        float3 ray_pos = _Position.xyz + ray_dir * adv;
        float4 ray_pos4 = mul(UNITY_MATRIX_MVP, float4(ray_pos, 1.0));
        ray_pos4.y *= _ProjectionParams.x;
        float2 ray_coord = ray_pos4.xy / ray_pos4.w * 0.5 + 0.5 + HalfPixelSize;
        float ray_depth = ComputeDepth(ray_pos4);
        float ref_depth = GetDepth(ray_coord);
#if ENABLE_BACKDEPTH
#endif

        //if(ray_depth > ref_depth) { discard; }
    }

    // todo
    float4 albedo = GetAlbedo(coord);
    float4 specular = GetSpecular(coord);
    float4 normal = GetNormal(coord);
    r.color = _Color;
    return r;
}

ps_out frag_line(vs_out i)
{
    return frag_point(i); // todo
}
ENDCG

    // point light
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
