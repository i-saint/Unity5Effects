// Upgrade NOTE: commented out 'float4x4 _WorldToCamera', a built-in variable
// Upgrade NOTE: replaced '_WorldToCamera' with 'unity_WorldToCamera'

Shader "Hidden/ScreenSpaceReflections" {
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
sampler2D _PrePassBuffer;
sampler2D _ReflectionBuffer;
sampler2D _AccumulationBuffer;
float4 _PrePassBuffer_TexelSize;

float4 _Params0;
float4 _Params1;
float4 _BlurOffset;
// float4x4 _WorldToCamera;

#define _Intensity          _Params0.x
#define _RayMarchDistance   _Params0.y
#define _RayDiffusion       _Params0.z
#define _FalloffDistance    _Params0.w
#define _MaxAccumulation    _Params1.x
#define _RayHitRadius       _Params1.y
#define _InvRayHitRadius    (1.0/_RayHitRadius)
#define _RayStepBoost       _Params1.z

// on OpenGL ES platforms, shader compiler goes infinite loop (?) without this workaround...
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
    // SAMPLES_LOW
    #define MAX_MARCH 12
    #define MAX_TRACEBACK_MARCH 4
    #define NUM_RAYS 1
#else
    #if SAMPLES_LOW
        #define MAX_MARCH 12
        #define MAX_TRACEBACK_MARCH 4
        #define NUM_RAYS 1
    #elif SAMPLES_HIGH
        #define MAX_MARCH 32
        #define MAX_TRACEBACK_MARCH 8
        //#define NUM_RAYS 2
    #else // SAMPLES_MEDIUM
        #define MAX_MARCH 16
        #define MAX_TRACEBACK_MARCH 8
        #define NUM_RAYS 1
    #endif
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
#if SHADER_API_D3D9
    #define UVOffset ((_ScreenParams.zw-1.0)*0.5)
#else
    #define UVOffset 0.0
#endif

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


struct RayHitData
{
    float hit;
    float advance;
    float3 pos;
    float2 uv;
};

RayHitData RayMarching(float adv, float3 p, float3 vp, float3 n, float smoothness, float march_step, const int max_march, const int max_traceback)
{
    float3x3 proj = tofloat3x3(unity_CameraProjection);

    //float3 vp = mul(_WorldToCamera, float4(p, 1.0)).xyz; // doesn't work on OpenGL
    float3 cam_dir = normalize(p - _WorldSpaceCameraPos);
    float3 ref_dir = normalize(reflect(cam_dir, n.xyz) + Diffusion(p, _RayDiffusion) * (1.0-smoothness));
    float3 ref_vdir = mul(tofloat3x3(unity_WorldToCamera), ref_dir);

    float hit = 0.0;
    float3 ray_vpos = 0.0;
    float2 ray_uv = 0.0;
    float ray_depth;
    float ref_depth;

    // raymarch
    for(int k=0; k<max_march; ++k) {
        adv += march_step;
        march_step *= (1.0+_RayStepBoost);
        ray_vpos = vp + ref_vdir * adv;

        float3 ray_ppos = mul(proj, ray_vpos);
        ray_uv = ray_ppos.xy / ray_vpos.z * 0.5 + 0.5;
        ray_depth = ray_vpos.z;
        ref_depth = GetLinearDepth(ray_uv);

        if(ray_depth > ref_depth) {
            hit = 1.0;
            break;
        }
    }

    // trace back
    for(int l=0; l<max_traceback; ++l) {
        adv -= march_step / (max_traceback+1);
        float3 ray_vpos_ = vp + ref_vdir * adv;
        float3 ray_ppos = mul(proj, ray_vpos_);
        float2 ray_uv_ = ray_ppos.xy / ray_vpos_.z * 0.5 + 0.5 ;
        float ray_depth_ = ray_vpos_.z;
        float ref_depth_ = GetLinearDepth(ray_uv_);

        if(ray_depth_ < ref_depth_) {
            break;
        }
        ray_uv = ray_uv_;
        ray_vpos = ray_vpos_;
        ray_depth = ray_depth_;
        ref_depth = ref_depth_;
    }

    float3 ray_pos = p + ref_dir * adv;
    float3 ref_pos = GetPosition(ray_uv);
    float3 ref_normal = GetNormal(ray_uv);
    if(/*dot(ref_normal, ref_dir) > 0.0 ||*/
        (ray_depth - ref_depth) > _RayHitRadius)
    {
        hit = 0.0;
    }

    RayHitData r;
    r.hit = hit;
    r.advance = adv;
    r.pos = ray_pos;
    r.uv = ray_uv;
    return r;
}

void SampleHitFragment(RayHitData ray, float smoothness, inout float4 hit_color, inout float accumulation)
{
    float2 edge = abs(ray.uv * 2.0 - 1.0);
    float edge_attr = pow(1.0 - max(edge.x, edge.y), 0.5);

#if ENABLE_DANGEROUS_SAMPLES
    accumulation *= max(1.0 - GetVelocity(ray.uv).z * 1.0 * _InvRayHitRadius, 0.25);
#endif

    hit_color.a = max(1.0 - (ray.advance / _FalloffDistance), 0.0) * edge_attr * smoothness * ray.hit;
    hit_color.rgb = tex2D(_MainTex, ray.uv).rgb;
}


half4 frag_prepass(vs_out i) : SV_Target
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w + UVOffset;
    float2 spos = uv * 2.0 - 1.0;

    float depth = GetDepth(uv);
    if (depth == 1.0) { return 0.0; }

    float3 p = GetPosition(spos, depth);
    float3 vp = GetViewPosition(spos, LinearEyeDepth(depth));
    float3 n = GetNormal(uv);
    float4 smoothness = GetSpecular(uv).w;

    const int max_march = MAX_MARCH;
    const int max_traceback = 4;
    float march_step = _RayMarchDistance / max_march;
    float adv = 0.0;
    adv += march_step * Jitter(p);

    RayHitData hit = RayMarching(adv, p, vp, n, smoothness, march_step, max_march, max_traceback);
    return hit.advance - march_step*0.25;
}


struct reflection_out
{
    half4 color : SV_Target0;
    half4 accumulation : SV_Target1;
};

reflection_out frag_reflections(vs_out i)
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w + UVOffset*2;
    float2 spos = uv * 2.0 - 1.0;

    reflection_out r;
    r.color = 0.0;
    r.accumulation = 0.0;

    float depth = GetDepth(uv);
    if(depth == 1.0) { return r; }

    float3 p = GetPosition(spos, depth);
    float3 vp = GetViewPosition(spos, LinearEyeDepth(depth));
    float3 n = GetNormal(uv);
    float4 smoothness = GetSpecular(uv).w;
    float4 vel = GetVelocity(uv);

    float2 prev_uv      = uv - vel.xy;
    float  prev_depth   = GetPrevDepth(prev_uv);
    float3 prev_pos     = GetPrevPosition(prev_uv*2.0 - 1.0, prev_depth);
    float4 ref_color    = tex2D(_ReflectionBuffer, prev_uv);
    float  accumulation = tex2D(_AccumulationBuffer, prev_uv).x * _MaxAccumulation;

    float adv = 0.0f;
#if ENABLE_PREPASS
    const int max_march = 4;
    const int max_traceback = 2;
    float march_step = _RayMarchDistance / (MAX_MARCH*2);

    float2 tx = float2(_PrePassBuffer_TexelSize.x, 0.0);
    float2 ty = float2(0.0, _PrePassBuffer_TexelSize.y);
    adv = min(tex2D(_PrePassBuffer, uv).r, min(tex2D(_PrePassBuffer, uv + tx).r, tex2D(_PrePassBuffer, uv - tx).r));
    adv = min(adv, min(tex2D(_PrePassBuffer, uv + ty).r, tex2D(_PrePassBuffer, uv - ty).r));
#else
    const int max_march = MAX_MARCH;
    const int max_traceback = MAX_TRACEBACK_MARCH;
    float march_step = _RayMarchDistance / MAX_MARCH;
    adv += march_step * Jitter(p);
#endif


    RayHitData hit = RayMarching(adv, p, vp, n, smoothness, march_step, max_march, max_traceback);

    float diff = vel.w;
    accumulation *= max(1.0-(0.02+diff*20.0), 0.0);

    float4 hit_color;
    SampleHitFragment(hit, smoothness, hit_color, accumulation);
    ref_color = ref_color * accumulation + hit_color;
    accumulation += 1.0;

    r.color = ref_color / accumulation;
    r.accumulation = min(accumulation, _MaxAccumulation) / _MaxAccumulation;
    return r;
}


half4 frag_blur(vs_out i) : SV_Target
{
    const float weights[5] = {0.05, 0.09, 0.12, 0.16, 0.16};
    float2 uv = i.screen_pos.xy / i.screen_pos.w;
    float2 o = _BlurOffset.xy;

    float4 r = 0.0;
    r += tex2D(_ReflectionBuffer, uv - o*4.0) * weights[0];
    r += tex2D(_ReflectionBuffer, uv - o*3.0) * weights[1];
    r += tex2D(_ReflectionBuffer, uv - o*2.0) * weights[2];
    r += tex2D(_ReflectionBuffer, uv - o*1.0) * weights[3];
    r += tex2D(_ReflectionBuffer, uv        ) * weights[4];
    r += tex2D(_ReflectionBuffer, uv + o*1.0) * weights[3];
    r += tex2D(_ReflectionBuffer, uv + o*2.0) * weights[2];
    r += tex2D(_ReflectionBuffer, uv + o*3.0) * weights[1];
    r += tex2D(_ReflectionBuffer, uv + o*4.0) * weights[0];
    return r;
}


float4 frag_combine(vs_out i) : SV_Target
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w;

    float accumulation = tex2D(_AccumulationBuffer, uv).x;
    float4 color = tex2D(_MainTex, uv);
    float4 ref_color = tex2D(_ReflectionBuffer, uv);
    float alpha = saturate(ref_color.a * _Intensity);
    return float4(lerp(color.rgb, ref_color.rgb, alpha), 1.0);
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_reflections
        #pragma target 3.0
        #pragma multi_compile SAMPLES_LOW SAMPLES_MEDIUM SAMPLES_HIGH
        #pragma multi_compile ___ ENABLE_PREPASS
        #pragma multi_compile ___ ENABLE_DANGEROUS_SAMPLES
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
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_prepass
        #pragma target 3.0
        #pragma multi_compile SAMPLES_LOW SAMPLES_MEDIUM SAMPLES_HIGH
        ENDCG
    }
}
}
