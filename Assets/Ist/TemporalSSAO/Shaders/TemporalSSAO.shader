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
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"
sampler2D _MainTex;
sampler2D _AOBuffer;
sampler2D _RandomTexture;

float4 _Params0;
float4 _BlurOffsetScale;
float4 _BlurOffset;
float4x4 _WorldToCamera;

#define _Radius             _Params0.x
#define _Intensity          _Params0.y

#define _MaxAccumulation    20.0
#define _DepthMinSimilarity 0.01
#define _VelocityScalar     0.01


struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXuv0;
};

struct ps_out
{
    half4 result : SV_Target0;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = v.vertex;
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

vs_out vert_combine(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)


float nrand(float2 uv, float dx, float dy)
{
    uv += float2(dx, dy + _Time.x);
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}


#define SAMPLE_COUNT 8

float3 spherical_kernel(float2 uv, float index)
{
    //return tex2D(_RandomTexture, uv*12.3456789+index+_Time.y).xyz * 2.0 - 1.0;

    // Uniformaly distributed points
    // http://mathworld.wolfram.com/SpherePointPicking.html
    float u = nrand(uv, 0, index) * 2 - 1;
    float theta = nrand(uv, 1, index) * UNITY_PI * 2;
    float u2 = sqrt(1 - u * u);
    float3 v = float3(u2 * cos(theta), u2 * sin(theta), u);
    // Adjustment for distance distribution.
    float l = index / SAMPLE_COUNT;
    return v * lerp(0.1, 1.0, l * l);
}


half4 frag_ao(vs_out i) : SV_Target
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w + HalfPixelSize;
    float2 screen_pos = uv * 2.0 - 1.0;

    float depth = GetDepth(uv);
    if(depth == 1.0) { return 0.0; }

    float3 p = GetPosition(uv);
    float3 vp = GetViewPosition(uv);
    float3 n = GetNormal(uv).xyz;
    float3 vn = mul(tofloat3x3(_WorldToCamera), n);
    float3x3 proj = tofloat3x3(unity_CameraProjection);

    float2 prev_uv;
    float  prev_ao;
    float4 prev_depth;
    float3 prev_pos;
    float accumulation;
    {
        float4 ppos4 = mul(_PrevViewProj, float4(p.xyz, 1.0) );
        float2 pspos = ppos4.xy / ppos4.w;
        prev_uv = pspos * 0.5 + 0.5;
        float2 r = tex2D(_AOBuffer, prev_uv).rg;
        prev_ao = r.x;
        accumulation = r.y * _MaxAccumulation;
        prev_depth = GetPrevDepth(prev_uv);
        prev_pos = GetPrevPosition(pspos, prev_depth);
    }

    float depth_similarity = saturate(pow(prev_depth / depth, 4) + _DepthMinSimilarity);
    float velocity = length(p.xyz - prev_pos.xyz);
    float velocity_similarity = saturate(velocity * _VelocityScalar);

    accumulation *= max(1.0-(0.05 + velocity*20.0), 0.0);
    float ao = prev_ao * accumulation;

    float occ = 0.0;
    for (int s = 0; s < SAMPLE_COUNT; s++)
    {
        float3 delta = spherical_kernel(uv, s);
        delta *= (dot(vn, delta) >= 0.0) * 2.0 - 1.0;

        float3 tpos = vp + delta * _Radius;
        float3 spos = mul(proj, tpos);
        float2 tuv = spos.xy / tpos.z * 0.5 + 0.5;
        float tdepth = GetLinearDepth(tuv);

        float dist = tpos.z - tdepth;
        occ += (dist > 0.01 * _Radius) * (dist < _Radius);
    }

    occ = saturate(occ * _Intensity / SAMPLE_COUNT);

    ao += occ;
    accumulation += 1.0;
    return half4(ao / accumulation, accumulation / _MaxAccumulation, 0.0, 0.0);
}



inline half CheckSame(float4 nd, float4 nnd)
{
    half sn = dot(abs(nd.xyz - nnd.xyz), 1.0) < 0.1;
    half sz = abs(nd.w - nnd.w) * _ProjectionParams.z < 0.2;
    return sn * sz;
}

half4 frag_blur(vs_out i) : SV_Target
{
#define NUM_BLUR_SAMPLES 4

    float2 uv = i.screen_pos.xy / i.screen_pos.w + HalfPixelSize;
    half sum = tex2D(_AOBuffer, uv).r * (NUM_BLUR_SAMPLES + 1);
    half denom = NUM_BLUR_SAMPLES + 1;

    float4 geom = float4(GetNormal(uv).xyz, GetDepth(uv));
    int s;
    for (s = 0; s < NUM_BLUR_SAMPLES; ++s)
    {
        float2 nuv = uv + _BlurOffset.xy * (s + 1);
        float4 ngeom = float4(GetNormal(nuv).xyz, GetDepth(nuv));
        half coef = (NUM_BLUR_SAMPLES - s) * CheckSame(geom, ngeom);
        sum += tex2D(_AOBuffer, nuv.xy).r * coef;
        denom += coef;
    }
    for (s = 0; s < NUM_BLUR_SAMPLES; ++s)
    {
        float2 nuv = uv - _BlurOffset.xy * (s + 1);
        float4 ngeom = float4(GetNormal(nuv).xyz, GetDepth(nuv));
        half coef = (NUM_BLUR_SAMPLES - s) * CheckSame(geom, ngeom);
        sum += tex2D(_AOBuffer, nuv.xy).r * coef;
        denom += coef;
    }
    return sum / denom;
}



half4 frag_combine(vs_out i) : SV_Target
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w + HalfPixelSize;

    half4 c = tex2D(_MainTex, uv);
    half ao = tex2D(_AOBuffer, uv).r;
    c.rgb = lerp(c.rgb, 0.0, ao);
    //return ao;
    return c;
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_ao
        #pragma target 3.0
        ENDCG
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_blur
        #pragma target 3.0
        ENDCG
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert_combine
        #pragma fragment frag_combine
        #pragma target 3.0
        ENDCG
    }
}
}
