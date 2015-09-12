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
sampler2D _AccumulationBuffer;

float4 _Params0;
float4 _BlurOffsetScale;
float4 _BlurOffset;

#define _AOPow              _Params0.x
#define _Radius             _Params0.y
#define _MinZ               _Params0.z
#define _Attenuation        _Params0.w
#define _MaxAccumulation    20.0


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

float Jitter(float3 p)
{
    float v = dot(p,1.0)+_Time.y;
    return frac(sin(v)*43758.5453);
}
float3 Diffusion(float3 p, float d)
{
    p *= _Time.y;
    return (float3(frac(sin(p)*43758.5453))*2.0-1.0) * d;
}

/*
ps_out frag_ao(v2f_ao i, int sampleCount, float3 samples[INPUT_SAMPLE_COUNT])
{
    // read random normal from noise texture
    half3 randN = tex2D(_RandomTexture, i.uvr).xyz * 2.0 - 1.0;

    // read scene depth/normal
    float4 depthnormal = tex2D(_CameraDepthTexture, i.uv);
    float3 viewNorm;
    float depth;
    DecodeDepthNormal(depthnormal, depth, viewNorm);
    depth *= _ProjectionParams.z;
    float scale = _Params.x / depth;

    // accumulated occlusion factor
    float occ = 0.0;
    for (int s = 0; s < sampleCount; ++s)
    {
        // Reflect sample direction around a random vector
        half3 randomDir = reflect(samples[s], randN);

        // Make it point to the upper hemisphere
        half flip = (dot(viewNorm, randomDir)<0) ? 1.0 : -1.0;
        randomDir *= -flip;
        // Add a bit of normal to reduce self shadowing
        randomDir += viewNorm * 0.3;

        float2 offset = randomDir.xy * scale;
        float sD = depth - (randomDir.z * _Params.x);

        // Sample depth at offset location
        float4 sampleND = tex2D(_CameraDepthNormalsTexture, i.uv + offset);
        float sampleD;
        float3 sampleN;
        DecodeDepthNormal(sampleND, sampleD, sampleN);
        sampleD *= _ProjectionParams.z;
        float zd = saturate(sD - sampleD);
        if (zd > _Params.y) {
            // This sample occludes, contribute to occlusion
            occ += pow(1 - zd, _Params.z); // sc2
                                           //occ += 1.0-saturate(pow(1.0 - zd, 11.0) + zd); // nullsq
                                           //occ += 1.0/(1.0+zd*zd*10); // iq
        }
    }
    occ /= sampleCount;
    return 1 - occ;
}
*/

ps_out frag_ao(vs_out i)
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w + HalfPixelSize;

    ps_out r;
    r.result = 0.0;

    float depth = GetDepth(uv);
    if(depth == 1.0) { return r; }

    float4 p = GetPosition(uv);
    float4 n = GetNormal(uv);
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos);

    float2 prev_uv;
    float  prev_ao;
    float4 prev_pos;
    float accumulation;
    {
        float4 ppos = mul(_PrevViewProj, float4(p.xyz, 1.0) );
        prev_uv = (ppos.xy / ppos.w) * 0.5 + 0.5;
        float2 r = tex2D(_AOBuffer, prev_uv).rg;
        prev_ao = r.x;
        accumulation = r.y * _MaxAccumulation;
        prev_pos = GetPrevPosition(uv);
    }

    float velocity = length(p.xyz-prev_pos.xyz);
    accumulation *= max(1.0-(0.05+ velocity*20.0), 0.0);
    float ao = prev_ao * accumulation;
    // todo: add ao

    r.result.xy = float2(ao, accumulation);
    return r;
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



float4 frag_combine(vs_out i) : SV_Target
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w + HalfPixelSize;

    half4 c = tex2D(_MainTex, uv);
    half ao = tex2D(_AOBuffer, uv).r;
    ao = pow(ao, _AOPow);
    c.rgb *= ao;
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
