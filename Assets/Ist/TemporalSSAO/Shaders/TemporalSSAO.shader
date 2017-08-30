// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4x4 _WorldToCamera', a built-in variable
// Upgrade NOTE: replaced '_WorldToCamera' with 'unity_WorldToCamera'

Shader "Hidden/TemporalSSAO" {
Properties{
    _MainTex("Base (RGB)", 2D) = "" {}
}
SubShader {
    Blend Off
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/Foundation/Shaders/Math.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"
sampler2D _MainTex;
sampler2D _AOBuffer;
sampler2D _RandomTexture;

float4 _Params0;
float4 _BlurOffset;
// float4x4 _WorldToCamera;

#define _Radius             _Params0.x
#define _InvRadius          (1.0/_Params0.x)
#define _Intensity          _Params0.y
#define _MaxAccumulation    _Params0.z

#define _DepthMinSimilarity 0.01
#define _VelocityScalar     0.01

#if SAMPLES_LOW
    #define _SampleCount 4
#elif SAMPLES_HIGH
    #define _SampleCount 12
#else // SAMPLES_MEDIUM
    #define _SampleCount 8
#endif


struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
};

struct ps_out
{
    half4 result : SV_Target0;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = v.vertex;
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

vs_out vert_combine(ia_out v)
{
    vs_out o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#if SHADER_API_D3D9
    #define UVOffset ((_ScreenParams.zw-1.0)*0.5)
#else
    #define UVOffset 0.0
#endif


float nrand(float2 uv, float dx, float dy)
{
    uv += float2(dx, dy + _Time.x);
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}


// from keijiro's code
float3 random_hemisphere(float2 uv, float index)
{
    // Uniformaly distributed points
    // http://mathworld.wolfram.com/SpherePointPicking.html

    float u = nrand(uv, 0, index);
    float theta = nrand(uv, 1, index) * UNITY_PI * 2;
    float u2 = sqrt(1 - u * u);

    float3 v = float3(u2 * cos(theta), u2 * sin(theta), u);
    // Adjustment for distance distribution.
    float l = index / _SampleCount;
    return v * lerp(0.5, 1.0, l * l);
}


half4 frag_ao(vs_out I) : SV_Target
{
    float2 uv = I.screen_pos.xy / I.screen_pos.w + UVOffset*2.0;
    float2 screen_pos = uv * 2.0 - 1.0;

    float depth = GetDepth(uv);
    if(depth == 1.0) { return 0.0; }

    float3 vp = GetViewPosition(uv);
    float3 n = GetNormal(uv);
    float3 vn = mul(tofloat3x3(unity_WorldToCamera), n);
    //float3 vn = -normalize(cross(ddx(vp), ddy(vp))); // not good :(
    float4 vel = GetVelocity(uv);

    float2 prev_uv      = uv - vel.xy;
    float  prev_depth   = GetPrevDepth(prev_uv);
    float2 prev_result  = tex2D(_AOBuffer, prev_uv).rg;
    float  accumulation = prev_result.y * _MaxAccumulation;
    float  ao           = prev_result.x;


    float diff = vel.z;
    accumulation *= max(1.0-(0.01 + diff*10.0), 0.0);

    float occ = 0.0;
    float danger = 0.0;

    float3x3 look = Look33(vn, float3(0.0, 1.0, 0.1));
    float3x3 proj = tofloat3x3(unity_CameraProjection);
    for (int i = 0; i < _SampleCount; i++)
    {
        float3 delta = random_hemisphere(uv, i);
        delta = mul(look, delta);

        float3 svpos = vp + delta * _Radius;
        float3 sppos = mul(proj, svpos);
        float2 suv = sppos.xy / svpos.z * 0.5 + 0.5 + UVOffset;
        float  sdepth = svpos.z;
        float  fdepth = GetLinearDepth(suv);
        float dist = sdepth - fdepth;

        float accept = dist < _Radius;
        occ += (dist > 0.01 * _Radius) * accept;
#if ENABLE_DANGEROUS_SAMPLES
        danger = max(danger, GetVelocity(suv).z * accept);
#endif
    }
    occ = saturate(occ * _Intensity / _SampleCount);

    accumulation *= max(1.0 - danger * 2.0 * _InvRadius, 0.25);
    accumulation = max(accumulation, 0.0);
    ao *= accumulation;
    accumulation += 1.0;
    ao = (ao + occ) / accumulation;
    accumulation = min(accumulation, _MaxAccumulation) / _MaxAccumulation;
    return half4(ao, accumulation, 0.0, 0.0);
}


half4 frag_blur(vs_out i) : SV_Target
{
    const float weights[5] = {0.05, 0.09, 0.12, 0.16, 0.16};
    float2 uv = i.screen_pos.xy / i.screen_pos.w + UVOffset;

    float2 ref = tex2D(_AOBuffer, uv).rg;
    float accumulation = ref.g;
    float2 o = _BlurOffset.xy * max( 2.5 - accumulation*_MaxAccumulation*0.25, 1.0 );

    float ao = ref.r * weights[4];
    float denom = weights[4];

    float c1 = 1.0;
    for (int i = 0; i < 4; ++i) {
        float2 nuv = uv + o*i;
#if BLUR_HORIZONTAL
        c1 *= GetContinuity(nuv).x;
#elif BLUR_VERTICAL
        c1 *= GetContinuity(nuv).z;
#endif
        ao += tex2D(_AOBuffer, nuv).r * weights[i] * c1;
        denom += weights[i] * c1;
    }

    float c2 = 1.0;
    for (int i = 0; i < 4; ++i) {
        float2 nuv = uv - o*i;
#if BLUR_HORIZONTAL
        c2 *= GetContinuity(nuv).y;
#elif BLUR_VERTICAL
        c2 *= GetContinuity(nuv).w;
#endif
        ao += tex2D(_AOBuffer, nuv).r * weights[i] * c2;
        denom += weights[i] * c2;
    }
    ao /= denom;
    return half4(ao, (c1+c2)*0.5, 0.0, 0.0);
    return half4(ao, accumulation, 0.0, 0.0);
}



half4 frag_combine(vs_out I) : SV_Target
{
    float2 uv = I.screen_pos.xy / I.screen_pos.w + UVOffset;
    half4 c = tex2D(_MainTex, uv);
    half ao = tex2D(_AOBuffer, uv).r;
    c.rgb = lerp(c.rgb, 0.0, ao);

#if DEBUG_SHOW_AO
    c.rgb = 1.0 - ao;
#elif DEBUG_SHOW_VELOCITY
    c.rgb = GetVelocity(uv).b;
#elif DEBUG_SHOW_VIEW_NORMAL
    float3 n = GetNormal(uv);
    float3 vn = mul(tofloat3x3(unity_WorldToCamera), n);

    //float3 vp = GetViewPosition(uv);
    //float3 vn = -normalize(cross(ddx(vp), ddy(vp))); 

    c.rgb = vn * 0.5 + 0.5;
#endif
    return c;
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_ao
        #pragma target 3.0
        #pragma multi_compile SAMPLES_LOW SAMPLES_MEDIUM SAMPLES_HIGH
        #pragma multi_compile ___ ENABLE_DANGEROUS_SAMPLES
        ENDCG
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_blur
        #pragma target 3.0
        #pragma multi_compile BLUR_HORIZONTAL BLUR_VERTICAL
        ENDCG
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert_combine
        #pragma fragment frag_combine
        #pragma target 3.0
        #pragma multi_compile DEBUG_OFF DEBUG_SHOW_AO DEBUG_SHOW_VELOCITY DEBUG_SHOW_VIEW_NORMAL
        ENDCG
    }
}
}
